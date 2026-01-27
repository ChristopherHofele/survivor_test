import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:survivor_test/survivor_test.dart';

enum Shooter { Player, Enemy }

class Projectile extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest> {
  Vector2 moveDirection;
  Shooter shooter;
  Projectile({
    required position,
    required this.moveDirection,
    this.shooter = Shooter.Player,
  }) : super(position: position, size: Vector2(38, 38), anchor: Anchor.center);

  int hitCounter = 0;
  int maxHits = 3;
  double damage = 10;
  double moveSpeed = 200;
  double despawnCounter = 5;
  Vector2 velocity = Vector2.zero();
  late String spriteName;

  @override
  FutureOr<void> onLoad() async {
    if (shooter == Shooter.Player) {
      spriteName = 'Traps/Saw/On.png';
    } else {
      spriteName = 'Traps/Saw/On_enemy.png';
    }

    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache(spriteName),
      SpriteAnimationData.sequenced(
        amount: 8,
        textureSize: Vector2(38, 38),
        stepTime: 0.02,
      ),
    );
    add(CircleHitbox(collisionType: CollisionType.passive));
    maxHits = game.player.projectileMaximumHits;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updateMovement(dt);
    _handleHits();
    _handleTime(dt);
    super.update(dt);
  }

  void _updateMovement(double dt) {
    velocity = moveDirection.normalized() * moveSpeed;
    position += velocity * dt;
  }

  void _handleHits() {
    if (hitCounter >= maxHits) {
      removeFromParent();
    }
  }

  void _handleTime(double dt) {
    despawnCounter -= dt;
    if (despawnCounter <= 0) {
      removeFromParent();
    }
  }
}
