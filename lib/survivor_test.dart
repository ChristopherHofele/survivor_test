import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/painting.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/overlays/attack_button.dart';
import 'package:survivor_test/overlays/dash_button.dart';
import 'package:survivor_test/overlays/health_display.dart';
import 'package:survivor_test/level.dart';
import 'package:survivor_test/overlays/money_display.dart';

class SurvivorTest extends FlameGame
    with DragCallbacks, HasCollisionDetection, TapCallbacks {
  //late final CameraComponent cam;

  int heartAmount = 0;
  int enemyCount = 0;
  int maxEnemyCount = 12;
  int enemyBaseHealth = 10;
  int frames = 0;
  int doorsOpened = 0;
  int keySpawnrate = 10;
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
  bool keyCanSpawn = false;
  Color background = Color.fromARGB(255, 44, 96, 26);
  late AudioPool shootSound;

  @override
  Future<void> onLoad() async {
    _initializeLists();
    player = Player(position: Vector2(960, 960));
    await images.loadAllImages();
    await FlameAudio.audioCache.loadAll([
      'the_return_of_the_8_bit_era.mp3',
      'power_off.mp3',
    ]);
    FlameAudio.bgm.initialize;
    shootSound = await AudioPool.createFromAsset(
      path: 'power_off.mp3',
      minPlayers: 3,
      maxPlayers: 6,
      audioCache: FlameAudio.audioCache,
    );
    loadWorld(player, 'Level1.tmx');
    camera = CameraComponent.withFixedResolution(
      world: world1,
      width: size.x,
      height: size.y + 300,
    );
    camera.follow(player);
    addControls();
    addHearts();
    addMoney();
    FlameAudio.bgm.play('the_return_of_the_8_bit_era.mp3');
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

    /*if (ticker >= 77) {
      FlameAudio.bgm.play('the_return_of_the_8_bit_era.mp3');
      ticker = 0;
    }*/
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
