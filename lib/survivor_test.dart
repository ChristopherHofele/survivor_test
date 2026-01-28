import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
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
  int frames = 0;
  double ticker = 0;
  late Player player;
  late JoystickComponent joystick;
  late DashButton dashButton;
  late AttackButton attackButton;
  late Level world1;
  bool startGame = false;
  Map spawnCoordinates = {};

  @override
  Future<void> onLoad() async {
    spawnCoordinates['Level1.tmx'] = Vector2(960, 960);
    spawnCoordinates['Health.tmx'] = Vector2(1040, 352);
    player = Player(position: Vector2(960, 960));
    await images.loadAllImages();
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
  }

  @override
  void update(double dt) {
    updateJoystick();
    if (player.health < 100) {
      startGame = false;
      overlays.add('GameOver');
    }
    ticker += dt;
    frames += 1;
    if (ticker >= 1) {
      print(frames);
      frames = 0;
      ticker = 0;
    }
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

  void updateHearts() {
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
}
