import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:survivor_test/survivor_test.dart';

class LightningBall extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest> {
  LightningBall({required position})
    : super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  double damage = 20;
  double duration = 1;

  @override
  FutureOr<void> onLoad() async {
    priority = 2;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('LightningBall.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(64, 64),
        stepTime: 0.083,
      ),
    );
    add(CircleHitbox(collisionType: CollisionType.passive));
    game.player.isVisible = false;
    game.electricitySound.start();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    duration -= dt;
    position = game.player.position;
    game.player.isDashing = true;
    game.player.canDash = true;
    _handleExistence();
    super.update(dt);
  }

  void _handleExistence() {
    if (duration <= 0) {
      game.player.isVisible = true;
      game.player.isDashing = false;
      game.player.canDash = false;
      removeFromParent();
    }
  }
}
