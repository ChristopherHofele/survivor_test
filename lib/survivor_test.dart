import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/painting.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/level.dart';

class SurvivorTest extends FlameGame
    with DragCallbacks, HasCollisionDetection, TapCallbacks {
  //late final CameraComponent cam;
  late Player player;
  late JoystickComponent joystick;

  @override
  Future<void> onLoad() async {
    player = Player(position: Vector2(700, 400));
    await images.loadAllImages();
    Level world = Level(player: player);
    camera = CameraComponent.withFixedResolution(
      world: world,
      width: size.x,
      height: size.y,
    );

    add(camera);
    camera.follow(player);
    add(world..priority = -1);
    world.add(player);
    addJoystick();
  }

  @override
  void update(double dt) {
    updateJoystick();
    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
      //position: Vector2(size.x - 100, size.y - 100),
      priority: 100,
      knob: SpriteComponent(sprite: Sprite(images.fromCache('HUD/Knob.png'))),
      background: SpriteComponent(
        sprite: Sprite(images.fromCache('HUD/Joystick.png')),
      ),
      margin: const EdgeInsets.only(right: 64, bottom: 64),
    );
    camera.viewport.add(joystick);
  }

  void updateJoystick() {
    if (joystick.direction != JoystickDirection.idle) {
      player.movementDirection = joystick.relativeDelta;
    } else {
      player.movementDirection = Vector2.zero();
    }
  }
}
