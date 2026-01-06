import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:survivor_test/components/player.dart';

class SurvivorTest extends FlameGame with TapCallbacks {
  late Player _player;

  @override
  Future<void> onLoad() async {
    await images.load('monster.png');
    camera.viewfinder.anchor = Anchor.topLeft;
    _player = Player(position: Vector2(128, size.y / 2));
    add(world);
    world.add(_player);
  }
}
