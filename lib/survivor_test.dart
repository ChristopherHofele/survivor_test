import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/overlays/attack_button.dart';
import 'package:survivor_test/overlays/dash_button.dart';
import 'package:survivor_test/overlays/health_display.dart';
import 'package:survivor_test/level.dart';
import 'package:survivor_test/overlays/money_display.dart';

class SurvivorTest extends FlameGame
    with DragCallbacks, HasCollisionDetection, TapCallbacks {
  int heartAmount = 0;
  int enemyCount = 0;
  int maxEnemyCount = 12;
  int enemyBaseHealth = 10;
  int frames = 0;
  int doorsOpened = 0;
  int keySpawnrate = 2;
  int enemyThresholdsBroken = 0;
  double ticker = 0;

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

  late Player player;
  late JoystickComponent joystick;
  late DashButton dashButton;
  late AttackButton attackButton;
  late Level world1;
  bool startGame = false;
  bool hasBeenToDamage = false;
  bool hasBeenToStamina = false;
  bool hasBeenToHealth = false;
  bool keyCanSpawn = true;

  Color background = Color.fromARGB(255, 44, 96, 26);

  late AudioSource shootSoundEnemy;
  late AudioSource gotHitSoundEnemy;

  @override
  Future<void> onLoad() async {
    _initializeLists();
    player = Player(
      position: Vector2(960, 1020),
      characterChoice: CharacterChoice.DashMan,
    );
    await images.loadAllImages();
    await FlameAudio.audioCache.loadAll([
      'the_return_of_the_8_bit_era.mp3',
      'Evening Harmony.mp3',
      'Gentle Breeze.mp3',
      'Golden Gleam.mp3',
      'Sunlight Through Leaves.mp3',
      'Sword Blocked 1.wav',
      'Bow Blocked 1.wav',
      'Sword Unsheath 2.wav',
      'Fireball 1.wav',
      'Apple Crunch.mp3',
      'Wave Attack 1.wav',
      'Explosion.mp3',
      'Fuse.mp3',
      'Slash.mp3',
      'UpgradedSlash.mp3',
      'ElectricDash.mp3',
      'LightningChain.mp3',
    ]);
    FlameAudio.bgm.initialize;

    loadWorld(player, 'Level1.tmx');
    camera = CameraComponent.withFixedResolution(
      world: world1,
      width: size.x,
      height: size.y,
    );
    camera.follow(player);
    addControls();
    addHearts();
    addMoney();
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
    if (player.health < 100) {
      startGame = false;
      overlays.add('GameOver');
    }
    ticker += dt;

    _updateHearts();
    _determineKeyCanSpawn();
    _updateMaxEnemyCount();

    super.update(dt);
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

  void _determineKeyCanSpawn() {
    if (player.hasKey == false) {
      if (hasBeenToDamage && hasBeenToHealth && hasBeenToStamina) {
        keyCanSpawn = true;
      }
    } else {
      keyCanSpawn = false;
    }
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
