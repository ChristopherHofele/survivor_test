import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/level.dart';

import 'package:survivor_test/survivor_test.dart';

class BasicEnemy extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest>, CollisionCallbacks {
  BasicEnemy({position})
    : super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  double moveSpeed = 100;
  double health = 1;
  final double hitboxRadius = 16;
  late final Player player;
  late final Level level;
  Vector2 movementDirection = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  List<CollisionBlock> collisionBlocks = [];
  List<BasicEnemy> basicEnemies = [];

  @override
  void onLoad() {
    player = game.player;
    collisionBlocks = player.collisionBlocks;
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
      _updateMovement(dt);
      basicEnemies = game.world1.basicEnemies;
      _handleHorizontalCollisions(dt);
      _handleVerticalCollisons(dt);
      _handleHealth();
    }
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is BasicEnemy && intersectionPoints.length == 2) {
      final mid =
          (intersectionPoints.elementAt(0) + intersectionPoints.elementAt(1)) /
          2;

      final collisionNormal = absoluteCenter - mid;
      final separationDistance = (16) - collisionNormal.length;
      collisionNormal.normalize();

      position += collisionNormal.scaled(separationDistance);
      for (final block in collisionBlocks) {
        if (checkCollision(this, block)) {
          position -= collisionNormal.scaled(separationDistance);
        }
      }
      super.onCollision(intersectionPoints, other);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Projectile) {
      health -= other.damage;
      other.hitCounter += 1;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  Vector2 determineMoveDirection(player) {
    Vector2 playerPointer = Vector2.zero();
    playerPointer.x = player.position.x - position.x;
    playerPointer.y = player.position.y - position.y;
    playerPointer.normalize();
    return playerPointer;
  }

  void _handleHorizontalCollisions(double dt) {
    for (final block in collisionBlocks) {
      if (checkCollision(this, block) &&
          isCollisionHorizontal(this, block, dt)) {
        if (velocity.x > 0) {
          velocity.x = 0;
          position.x = block.x - this.width / 2;
          break;
        }
        if (velocity.x < 0) {
          velocity.x = 0;
          position.x = block.x + block.width + this.width / 2;
          break;
        }
      }
    }
  }

  void _handleVerticalCollisons(double dt) {
    for (final block in collisionBlocks) {
      if (checkCollision(this, block) && isCollisionVertical(this, block, dt)) {
        if (velocity.y > 0) {
          velocity.y = 0;
          position.y = block.y - this.height / 2;
          break;
        }
        if (velocity.y < 0) {
          velocity.y = 0;
          position.y = block.y + block.height + this.height / 2;
        }
      }
    }
  }

  void _updateMovement(double dt) {
    movementDirection = determineMoveDirection(player);
    velocity = movementDirection * moveSpeed;
    position += velocity * dt;
  }

  void _handleHealth() {
    if (health <= 0) {
      removeFromParent();
      game.world1.enemyCount -= 1;
    }
  }
}
