import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:survivor_test/components/player.dart';
import 'package:survivor_test/level.dart';

class SurvivorTest extends FlameGame with TapCallbacks {
  late final CameraComponent cam;
  late Player _player;
  final world = Level();

  @override
  Future<void> onLoad() async {
    await images.load('monster.png');
    cam = CameraComponent.withFixedResolution(
      world: world,
      width: size.x,
      height: size.y,
    );
    //cam.viewfinder.anchor = Anchor.topLeft;

    _player = Player(position: Vector2(600, 400));
    cam.follow(_player);
    add(cam);
    add(world);
    world.add(_player);
  }
}
