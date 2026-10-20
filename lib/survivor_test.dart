import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/data/online_player.dart';
import 'package:survivor_test/data/personal_bests.dart';
import 'package:survivor_test/data/unlocks.dart';
import 'package:survivor_test/components/screen_shake.dart';
import 'package:survivor_test/overlays/attack_button.dart';
import 'package:survivor_test/overlays/dash_button.dart';
import 'package:survivor_test/overlays/health_display.dart';
import 'package:survivor_test/level.dart';
import 'package:survivor_test/overlays/money_display.dart';
import 'package:survivor_test/overlays/seed_display.dart';
import 'package:survivor_test/overlays/unlock_banner.dart';

class SurvivorTest extends FlameGame
    with DragCallbacks, HasCollisionDetection, TapCallbacks {
  // Called to throw this game away and go back to the start screen
  final void Function() onReturnToMenu;
  SurvivorTest({required this.onReturnToMenu});

  // How close the camera is: 1.0 shows the map at normal size,
  // higher numbers zoom in further
  static const double cameraZoom = 1.25;

  // ---- Testing shortcuts: set back to false before committing ----
  // Start the game carrying all three seeds (touch the lake to plant them)
  static const bool debugStartWithAllSeeds = false;
  // Level 1 spawns all three enemy types, each with the same chance,
  // without having visited the Stamina and Damage rooms first
  static const bool debugAllEnemyTypesInLevel1 = false;
  // Fight the boss at this level (1-4) every time; 0 = normal (off)
  static const int debugBossLevel = 0;
  // Empties the personal best list every time the game starts
  static const bool debugClearPersonalBests = false;
  // Forgets the leaderboard name every time the app starts, so the
  // "choose your name" window shows again
  static const bool debugClearPlayerName = false;
  // All characters can be chosen (nothing is saved, turning it off brings
  // the locks back)
  static const bool debugUnlockAllCharacters = false;
  // Forgets all unlocked characters and the enemy total every time the app
  // starts, so the milestones can be played through again
  static const bool debugResetUnlocks = false;

  // True while a switch is on that makes runs easier or different from a
  // normal game. Such runs are neither saved as a personal best nor sent to
  // the global leaderboard, so no test score ever ends up online.
  static bool get isTestRun =>
      debugStartWithAllSeeds ||
      debugAllEnemyTypesInLevel1 ||
      debugBossLevel != 0;

  int heartAmount = 0;
  int enemyCount = 0;
  int maxEnemyCount = 12;
  int enemyBaseHealth = 10;
  int frames = 0;
  int doorsOpened = 0;
  int enemyThresholdsBroken = 0;

  // Stats for the game over scoreboard
  int enemiesKilled = 0;
  double timeSurvived = 0;
  int timesHit = 0;
  // The level of every boss defeated in this run, e.g. [1, 2]
  final List<int> defeatedBossLevels = [];
  int get bossesDefeated => defeatedBossLevels.length;

  // ---- Character unlocks ----
  // How many of each fruit were eaten since the last boss (or the start)
  final Map<ItemType, int> fruitsSinceLastBoss = {};
  // True once the same fruit was eaten twice before a boss (Mine Fellow)
  bool ateSameFruitTwice = false;
  // Characters unlocked during this run and already announced with a
  // banner
  final Set<CharacterChoice> unlockedThisRun = {};
  // All characters unlocked in this run (shown on the game over screen)
  Future<List<CharacterChoice>>? newlyUnlocked;
  // Banner texts waiting to be shown (one banner at a time)
  final List<String> _bannerQueue = [];
  bool _bannerShowing = false;

  RunProgress get runProgress => RunProgress(
    bossesDefeated: bossesDefeated,
    enemiesKilled: enemiesKilled,
    ateSameFruitTwice: ateSameFruitTwice,
  );

  // Called by the player when they eat an apple, banana or cherry
  void fruitEaten(ItemType fruit) {
    final count = (fruitsSinceLastBoss[fruit] ?? 0) + 1;
    fruitsSinceLastBoss[fruit] = count;
    if (count >= 2) {
      ateSameFruitTwice = true;
    }
    checkUnlocks();
  }

  // Called by the boss when it dies
  void bossDefeated(int bossLevel) {
    defeatedBossLevels.add(bossLevel);
    // A new stretch begins: fruits eaten before this boss don't count
    fruitsSinceLastBoss.clear();
    checkUnlocks();
  }

  // Called by enemies when they die
  void enemyKilled() {
    enemiesKilled += 1;
    checkUnlocks();
  }

  // Checks the milestones right now and announces new characters with a
  // banner. They're saved immediately, so they're kept even if the app is
  // closed during the run (test runs only show them).
  void checkUnlocks() {
    final reached = Unlocks.newlyReached(
      runProgress,
      alreadyAnnounced: unlockedThisRun,
    );
    if (reached.isEmpty) return;
    unlockedThisRun.addAll(reached);
    if (!isTestRun) {
      unawaited(Unlocks.unlock(reached));
    }
    for (final character in reached) {
      final note = isTestRun ? ' (test run)' : '';
      _bannerQueue.add(
        'New character unlocked: ${characterNames[character]}!$note',
      );
    }
    _showNextBanner();
  }

  void _showNextBanner() {
    // After game over the game is paused, so no new banners
    if (_bannerShowing || _bannerQueue.isEmpty || isGameOver) return;
    _bannerShowing = true;
    camera.viewport.add(
      UnlockBanner(
        text: _bannerQueue.removeAt(0),
        onFinished: () {
          _bannerShowing = false;
          _showNextBanner();
        },
      ),
    );
  }

  // ---- Score: points per stat (shown on the game over screen) ----
  static const int pointsPerKill = 10;
  static const int pointsPerBossLevel = 1000; // a level 2 boss gives 2000
  static const int pointsPerSecond = 1;
  static const int pointsLostPerHit = 25;

  int get killPoints => enemiesKilled * pointsPerKill;
  int get bossPoints =>
      defeatedBossLevels.fold(0, (sum, level) => sum + level) *
      pointsPerBossLevel;
  int get timePoints => timeSurvived.floor() * pointsPerSecond;
  int get hitPoints => timesHit * pointsLostPerHit;
  // Never below 0
  int get finalScore {
    final total = killPoints + bossPoints + timePoints - hitPoints;
    return total < 0 ? 0 : total;
  }

  List<int> doorPrices = [20, 40, 50, 100, 0, 0, 0, 0, 0, 0];
  List<int> zeroDoorsMaxEnemyCounts = [1, 4, 8];
  List<int> oneDoorsMaxEnemyCounts = [8, 12, 16];
  List<int> twoDoorsMaxEnemyCounts = [10, 14, 20];
  List<int> threeDoorsMaxEnemyCounts = [12, 14, 20];
  List<List> maxEnemyCounts = [];

  List<int> zeroDoorsEnemyThresholds = [4, 40];
  List<int> oneDoorsEnemyThresholds = [40, 80];
  List<int> twoDoorsEnemyThresholds = [50, 100];
  List<int> threeDoorsEnemyThresholds = [100, 200];
  List<List> enemyThresholds = [];

  CharacterChoice selectedCharacter = CharacterChoice.Undecided;
  late Player player;
  late JoystickComponent joystick;
  late DashButton dashButton;
  late AttackButton attackButton;
  late Level world1;
  bool startGame = false;
  bool isGameOver = false;
  bool hasBeenToDamage = false;
  bool hasBeenToStamina = false;
  bool hasBeenToHealth = false;
  // Seed kinds planted at the lake statue towards its next activation
  final Set<ItemType> plantedSeeds = {};
  // Fruits the statue has offered that haven't been picked up yet.
  // Kept here so they're still there after leaving Level 1 and coming back.
  final List<ItemType> waitingGifts = [];

  Color background = Color.fromARGB(255, 44, 96, 26);

  late AudioSource shootSoundEnemy;
  late AudioSource gotHitSoundEnemy;
  late AudioSource bossBGM;
  late AudioSource introRoarSound;
  late AudioSource victorySound;

  @override
  Future<void> onLoad() async {
    if (debugClearPersonalBests) {
      await PersonalBests.clear();
    }
    _initializeLists();
    player = Player(position: Vector2(960, 1020));
    await images.loadAllImages();

    // No fixed resolution: the camera follows the screen's real size, even if
    // the game loaded while the phone was still in portrait (lock screen).
    // It's created before the first level, because each level sets up
    // the camera when it loads.
    camera = CameraComponent();
    camera.viewfinder.zoom = cameraZoom;
    loadWorld(player, 'Level1.tmx');
    addControls();
    addHearts();
    addMoney();
    camera.viewport.add(SeedDisplay());
    gotHitSoundEnemy = await SoLoud.instance.loadAsset(
      'assets/audio/Sword Blocked 1.wav',
      mode: LoadMode.memory,
    );
    shootSoundEnemy = await SoLoud.instance.loadAsset(
      'assets/audio/Sword Unsheath 2.wav',
      mode: LoadMode.memory,
    );
  }

  @override
  Color backgroundColor() => background;

  @override
  void update(double dt) {
    updateJoystick();
    if (player.health <= 0 && !isGameOver) {
      _triggerGameOver();
    }
    if (startGame) {
      timeSurvived += dt;
    }

    _updateHearts();
    _updateMaxEnemyCount();

    super.update(dt);
  }

  void _triggerGameOver() {
    isGameOver = true;
    startGame = false;
    SoLoud.instance.disposeAllSources();
    pauseEngine();
    _recordPersonalBest();
    // A last check (test runs show unlocks but don't save them). The game
    // over screen lists everything unlocked in this run.
    final announced = unlockedThisRun.toList();
    newlyUnlocked = Unlocks.finishRun(
      runProgress,
      save: !isTestRun,
      alreadyAnnounced: unlockedThisRun,
    ).then((lastOnes) => [...announced, ...lastOnes]);
    overlays.add('GameOver');
  }

  // Saving happens in the background; the personal best screen waits for
  // the result when it's shown
  Future<PersonalBestsResult>? personalBestsResult;

  void _recordPersonalBest() {
    final result = PersonalBests.add(
      ScoreEntry(
        score: finalScore,
        date: DateTime.now(),
        character: player.characterChoice,
      ),
      // A test run still shows where it would have placed, but isn't saved
      save: !isTestRun,
    );
    personalBestsResult = result;
    if (isTestRun) {
      debugPrint('Test run: score not saved and not sent to the leaderboard');
      return;
    }
    // Then send the best score on this device to the global leaderboard
    // (in the background; it only sends something if it's a new record)
    leaderboardSubmission = result.then(
      (saved) => OnlinePlayer.submitBest(saved.entries.first),
    );
  }

  // Sending the score to the global leaderboard. The leaderboard screen
  // waits for it, so a new record already shows up there.
  Future<SubmitResult>? leaderboardSubmission;

  // Shakes the screen briefly. A new shake replaces one that's still running.
  void shakeScreen() {
    for (final shake in children.whereType<ScreenShake>()) {
      shake.removeFromParent();
    }
    add(ScreenShake());
  }

  void addControls() {
    joystick = JoystickComponent(
      //position: Vector2(size.x - 100, size.y - 100),
      priority: 100,
      knob: SpriteComponent(sprite: Sprite(images.fromCache('HUD/Knob.png'))),
      background: SpriteComponent(
        sprite: Sprite(images.fromCache('HUD/Joystick.png')),
      ),
      margin: const EdgeInsets.only(right: 64, bottom: 64),
    );
    dashButton = DashButton();
    attackButton = AttackButton();
    camera.viewport.add(attackButton);
    camera.viewport.add(dashButton);
    camera.viewport.add(joystick);
  }

  void updateJoystick() {
    if (joystick.direction != JoystickDirection.idle) {
      player.movementDirection = joystick.relativeDelta;
    } else {
      player.movementDirection = Vector2.zero();
    }
  }

  void addHearts() {
    for (int i = 1; i <= player.maxHealth / 100; i++) {
      double heartX = 40 + (i - 1) * 40;
      double heartY = 40;
      Heart heart = Heart(heartID: i, position: Vector2(heartX, heartY));
      heartAmount += 1;
      camera.viewport.add(heart);
    }
  }

  void _updateHearts() {
    double heartDifference = player.maxHealth / 100 - heartAmount;
    if (heartDifference > 0) {
      heartAmount += 1;
      for (int i = 1; i <= heartDifference; i++) {
        double heartX = 40 + (heartAmount - 1) * 40;
        double heartY = 40;
        Heart heart = Heart(
          heartID: heartAmount,
          position: Vector2(heartX, heartY),
        );
        camera.viewport.add(heart);
      }
    }
  }

  void addMoney() {
    MoneyDisplay moneyDisplay = MoneyDisplay();
    camera.viewport.add(moneyDisplay);
  }

  void loadWorld(Player player, String worldName) {
    world1 = Level(player: player, tileMapName: worldName);
    add(world1..priority = -1);
    world1.add(player);
    camera.world = world1;
  }

  void resetMaxEnemyCount() {
    maxEnemyCount = 12;
  }

  void _updateMaxEnemyCount() {
    if (world1.tileMapName == 'Level1.tmx') {
      if (world1.enemiesDefeated >= enemyThresholds[doorsOpened][1]) {
        enemyThresholdsBroken = 2;
      } else if (world1.enemiesDefeated >= enemyThresholds[doorsOpened][0]) {
        enemyThresholdsBroken = 1;
      } else {
        enemyThresholdsBroken = 0;
      }
      maxEnemyCount = maxEnemyCounts[doorsOpened][enemyThresholdsBroken];
    }
    //print(maxEnemyCount);
  }

  void _initializeLists() {
    maxEnemyCounts = [
      zeroDoorsMaxEnemyCounts,
      oneDoorsMaxEnemyCounts,
      twoDoorsMaxEnemyCounts,
      threeDoorsMaxEnemyCounts,
    ];
    enemyThresholds = [
      zeroDoorsEnemyThresholds,
      oneDoorsEnemyThresholds,
      twoDoorsEnemyThresholds,
      threeDoorsEnemyThresholds,
    ];
  }
}
