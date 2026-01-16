import 'package:flame/components.dart';
import 'package:survivor_test/actors/player.dart';

import 'package:survivor_test/survivor_test.dart';

class BasicEnemy extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest> {
  BasicEnemy({position, player})
    : super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  double moveSpeed = 100;
  late final Player player;
  Vector2 movementDirection = Vector2.zero();
  Vector2 velocity = Vector2.zero();

  @override
  void onLoad() {
    player = game.player;
    priority = 1;
    debugMode = true;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('enemy.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(64, 64),
        stepTime: 0.12,
      ),
    );
  }

  @override
  void update(double dt) {
    movementDirection = determineMoveDirection(player);
    velocity = movementDirection * moveSpeed;
    position += velocity * dt;
    super.update(dt);
  }

  Vector2 determineMoveDirection(player) {
    Vector2 playerPointer = Vector2.zero();
    playerPointer.x = player.position.x - position.x;
    playerPointer.y = player.position.y - position.y;
    playerPointer.normalize();
    return playerPointer;
  }
}
