import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:survivor_test/survivor_test.dart';

class LightningChain extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest> {
  Vector2 endPosition;
  LightningChain({required position, required this.endPosition})
    : super(
        position: position,
        size: Vector2(256, 128),
        anchor: Anchor.centerLeft,
      );

  double damage = 0.083;
  double duration = 2;
  late Vector2 zapDirection;
  late RectangleHitbox hitbox;

  @override
  FutureOr<void> onLoad() async {
    //debugMode = true;
    priority = 2;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('LightningChain.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(256, 128), //!!!
        stepTime: 0.083,
      ),
    );
    zapDirection = determineZapDirection(position, endPosition);
    hitbox = RectangleHitbox(
      size: Vector2(size.x, size.y / 2 - 2),
      collisionType: CollisionType.passive,
    );
    hitbox.position.y += 32;
    _calculateAngle();
    _calculateScale();
    add(hitbox);
    return super.onLoad();
  }

  void _calculateAngle() {
    angle = atan2(zapDirection.y, zapDirection.x);
  }

  void _calculateScale() {
    scale.x *= zapDirection.length / width;
  }

  Vector2 determineZapDirection(Vector2 startPosition, Vector2 targetPosition) {
    Vector2 directionOfCorner = Vector2.zero();
    directionOfCorner.x = targetPosition.x - startPosition.x;
    directionOfCorner.y = targetPosition.y - startPosition.y;
    return directionOfCorner;
  }

  @override
  void update(double dt) {
    duration -= dt;
    _handleExistence();
    super.update(dt);
  }

  void _handleExistence() {
    if (duration <= 0) {
      game.player.zapFinished = true;
      removeFromParent();
    }
  }
}
