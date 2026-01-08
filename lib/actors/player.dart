import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:survivor_test/actors/utils.dart';
//import 'package:flutter/widgets.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/survivor_test.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest>, TapCallbacks, CollisionCallbacks {
  Player({position})
    : super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  double moveSpeed = 300;
  Vector2 movementDirection = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  List<CollisionBlock> collisionBlocks = [];

  @override
  void onLoad() {
    priority = 1;
    debugMode = true;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('monster.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(64, 60),
        stepTime: 0.12,
      ),
    );
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    _updatePlayerMovement(dt);
    _handleHorizontalCollisions();
    _handleVerticalCollisons();
    super.update(dt);
  }

  void _updatePlayerMovement(double dt) {
    velocity = movementDirection * moveSpeed;
    position += velocity * dt;
  }

  void _handleHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isShop) {
        if (checkCollision(this, block) && isCollisionHorizontal(this, block)) {
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
  }

  void _handleVerticalCollisons() {
    for (final block in collisionBlocks) {
      if (checkCollision(this, block) && !isCollisionHorizontal(this, block)) {
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
}
