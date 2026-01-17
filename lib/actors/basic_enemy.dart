import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/level.dart';

import 'package:survivor_test/survivor_test.dart';

class BasicEnemy extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest>, CollisionCallbacks {
  BasicEnemy({position})
    : super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  double moveSpeed = 100;
  final double hitboxRadius = 16;
  late final Player player;
  late final Level level;
  Vector2 movementDirection = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  List<BasicEnemy> basicEnemies = [];

  @override
  void onLoad() {
    player = game.player;

    priority = 1;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('enemy.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(64, 64),
        stepTime: 0.12,
      ),
    );
    add(
      CircleHitbox(
        radius: hitboxRadius,
        position: size / 2,
        anchor: Anchor.center,
        collisionType: CollisionType.active,
      ),
    );
  }

  @override
  void update(double dt) {
    if (game.startGame) {
      movementDirection = determineMoveDirection(player);
      velocity = movementDirection * moveSpeed;
      position += velocity * dt;
      basicEnemies = game.world1.basicEnemies;
    }
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is BasicEnemy) {
      final mid =
          (intersectionPoints.elementAt(0) + intersectionPoints.elementAt(1)) /
          2;

      final collisionNormal = absoluteCenter - mid;
      final separationDistance = (16) - collisionNormal.length;
      collisionNormal.normalize();

      // Resolve collision by moving ember along
      // collision normal by separation distance.
      position += collisionNormal.scaled(separationDistance);
      super.onCollision(intersectionPoints, other);
    }
  }

  Vector2 determineMoveDirection(player) {
    Vector2 playerPointer = Vector2.zero();
    playerPointer.x = player.position.x - position.x;
    playerPointer.y = player.position.y - position.y;
    playerPointer.normalize();
    return playerPointer;
  }
}
