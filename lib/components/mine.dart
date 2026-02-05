import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:survivor_test/survivor_test.dart';

enum MineState { Planted, Exploding }

class Mine extends SpriteAnimationGroupComponent
    with HasGameReference<SurvivorTest> {
  Mine({required position})
    : super(position: position, size: Vector2(32, 32), anchor: Anchor.center);

  int hitCounter = 0;

  double damage = 20;
  double moveSpeed = 200;
  double fuse = 2.5;
  double explosionDuration = 1;
  Vector2 velocity = Vector2.zero();

  bool isExploding = false;
  bool startedExploding = false;

  late final SpriteAnimation plantedAnimation;
  late final SpriteAnimation explodingAnimation;

  late CircleHitbox hitboxBig;
  late CircleHitbox hitboxMedium;
  late CircleHitbox hitboxSmall;
  @override
  FutureOr<void> onLoad() async {
    //debugMode = true;
    plantedAnimation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Bomb.png'),
      SpriteAnimationData.sequenced(
        amount: 3,
        textureSize: Vector2(32, 32),
        stepTime: 0.1,
      ),
    );
    explodingAnimation = SpriteAnimation.fromFrameData(
      game.images.fromCache('explosion-b.png'),
      SpriteAnimationData.sequenced(
        amount: 12,
        textureSize: Vector2(160, 96),
        stepTime: 0.083,
      ),
    );
    animations = {
      MineState.Planted: plantedAnimation,
      MineState.Exploding: explodingAnimation,
    };
    current = MineState.Planted;

    hitboxBig = CircleHitbox(
      collisionType: CollisionType.passive,
      radius: 80,
      anchor: Anchor.center,
    );
    add(hitboxBig);
    hitboxBig.position += Vector2(80, 40);
    hitboxMedium = CircleHitbox(
      collisionType: CollisionType.passive,
      radius: 45,
      anchor: Anchor.center,
    );
    add(hitboxMedium);
    hitboxMedium.position += Vector2(80, 40);
    hitboxSmall = CircleHitbox(
      collisionType: CollisionType.passive,
      radius: 30,
      anchor: Anchor.center,
    );
    add(hitboxSmall);
    hitboxSmall.position += Vector2(80, 40);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _handleStates(dt);
    if (current == MineState.Exploding) {
      if (!startedExploding) {
        game.explosionSound.start();
        startedExploding = true;
      }
      isExploding = true;
      explosionDuration -= dt;
    }
    if (explosionDuration <= 0) {
      removeFromParent();
    }
    super.update(dt);
  }

  void _handleStates(double dt) {
    fuse -= dt;
    if (fuse <= 0) {
      current = MineState.Exploding;
      size = Vector2(160, 96);
    }
  }
}
