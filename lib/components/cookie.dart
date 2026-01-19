import 'dart:async';

import 'package:flame/components.dart';

import 'package:survivor_test/survivor_test.dart';

class Cookie extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest> {
  final int worth;
  Cookie({required position, this.worth = 1})
    : super(position: position, size: Vector2.all(50));

  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Items/Fruits/cookie.png'),
      SpriteAnimationData.sequenced(
        amount: 8,
        textureSize: Vector2.all(32),
        stepTime: 0.12,
      ),
    );
    return super.onLoad();
  }
}
