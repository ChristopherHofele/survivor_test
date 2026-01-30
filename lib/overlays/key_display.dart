import 'dart:async';

import 'package:flame/components.dart';

import 'package:survivor_test/survivor_test.dart';

class KeyDisplay extends PositionComponent with HasGameReference<SurvivorTest> {
  KeyDisplay({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
  });
  @override
  FutureOr<void> onLoad() async {
    final keySprite = await game.loadSprite('Items/Fruits/Key_still.png');
    add(
      SpriteComponent(
        sprite: keySprite,
        position: Vector2(game.size.x / 2, 50),
        size: Vector2.all(32),
        anchor: Anchor.center,
      ),
    );
    return super.onLoad();
  }
}
