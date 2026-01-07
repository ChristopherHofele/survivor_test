import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
//import 'package:flutter/painting.dart';
import 'package:survivor_test/components/player.dart';
import 'package:survivor_test/level.dart';

class SurvivorTest extends FlameGame
    with DragCallbacks, HasCollisionDetection, TapCallbacks {
  late final CameraComponent cam;
  late Player player;
  final world = Level();
  late JoystickComponent _joystick;

  @override
  Future<void> onLoad() async {
    await images.loadAllImages();
    cam = CameraComponent.withFixedResolution(
      world: world,
      width: size.x,
      height: size.y,
    );
    //cam.viewfinder.anchor = Anchor.topLeft;

    player = Player(position: Vector2(700, 400));
    add(cam);
    cam.follow(player);
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
    _joystick = JoystickComponent(
      position: Vector2(size.x - 100, size.y - 100),
      priority: 100,
      knob: SpriteComponent(sprite: Sprite(images.fromCache('HUD/Knob.png'))),
      background: SpriteComponent(
        sprite: Sprite(images.fromCache('HUD/Joystick.png')),
      ),
    );
    cam.viewport.add(_joystick);
  }

  void updateJoystick() {
    switch (_joystick.direction) {
      case JoystickDirection.left:
        player.horizontalMovement = -1;
        player.verticalMovement = 0;
        break;
      case JoystickDirection.upLeft:
        player.horizontalMovement = -1;
        player.verticalMovement = -1;
        break;
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        player.verticalMovement = 1;
        break;
      case JoystickDirection.right:
        player.horizontalMovement = 1;
        player.verticalMovement = 0;
        break;
      case JoystickDirection.upRight:
        player.horizontalMovement = 1;
        player.verticalMovement = -1;
        break;
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        player.verticalMovement = 1;
        break;
      case JoystickDirection.up:
        player.horizontalMovement = 0;
        player.verticalMovement = -1;
        break;
      case JoystickDirection.down:
        player.horizontalMovement = 0;
        player.verticalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        player.verticalMovement = 0;
        break;
    }
  }
}
