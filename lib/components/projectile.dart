import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:survivor_test/survivor_test.dart';

class Projectile extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest> {
  Vector2 moveDirection;
  Projectile({required position, required this.moveDirection})
    : super(position: position, size: Vector2(38, 38), anchor: Anchor.center);

  int hitCounter = 0;
  int maxHits = 3;
  double damage = 10;
  double moveSpeed = 200;
  Vector2 velocity = Vector2.zero();

  @override
  FutureOr<void> onLoad() async {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Traps/Saw/On.png'),
      SpriteAnimationData.sequenced(
        amount: 8,
        textureSize: Vector2(38, 38),
        stepTime: 0.02,
      ),
    );
    add(CircleHitbox(collisionType: CollisionType.passive));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updateMovement(dt);
    _handleHits();
    super.update(dt);
  }

  void _updateMovement(double dt) {
    velocity = moveDirection * moveSpeed;
    position += velocity * dt;
  }

  void _handleHits() {
    if (hitCounter >= maxHits) {
      removeFromParent();
    }
  }
}
