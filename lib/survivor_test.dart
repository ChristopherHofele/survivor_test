import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/painting.dart';
import 'package:survivor_test/components/player.dart';
import 'package:survivor_test/level.dart';

class SurvivorTest extends FlameGame
    with DragCallbacks, HasCollisionDetection, TapCallbacks {
  late final CameraComponent cam;
  late Player _player;
  final world = Level();
  late JoystickComponent joystick;

  @override
  Future<void> onLoad() async {
    await images.loadAllImages();
    cam = CameraComponent.withFixedResolution(
      world: world,
      width: size.x,
      height: size.y,
    );
    //cam.viewfinder.anchor = Anchor.topLeft;

    _player = Player(position: Vector2(700, 400));
    cam.follow(_player);
    add(cam);
    addJoystick();
    add(world..priority = -1);
    world.add(_player);
  }

  @override
  void update(double dt) {
    updateJoystick();
    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
      priority: 100,
      knob: SpriteComponent(sprite: Sprite(images.fromCache('HUD/Knob.png'))),
      background: SpriteComponent(
        sprite: Sprite(images.fromCache('HUD/Joystick.png')),
      ),
      margin: const EdgeInsets.only(right: 400, bottom: 32),
    );
    add(joystick..priority = 100);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        _player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        _player.horizontalMovement = 1;
        break;
      case JoystickDirection.up:
        _player.verticalMovement = -1;
        break;
      case JoystickDirection.down:
        _player.verticalMovement = 1;
        break;
      default:
        _player.horizontalMovement = 0;
        _player.verticalMovement = 0;
        break;
    }
  }
}
