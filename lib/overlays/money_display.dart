import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:survivor_test/survivor_test.dart';

class MoneyDisplay extends PositionComponent
    with HasGameReference<SurvivorTest> {
  MoneyDisplay({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
  });
  late TextComponent _scoreTextComponent;

  @override
  Future<void> onLoad() async {
    _scoreTextComponent = TextComponent(
      text: '${game.world1.player.money}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Color.fromRGBO(10, 10, 10, 1),
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(-100, 50),
    );
    add(_scoreTextComponent);

    final cookieSprite = await game.loadSprite('Items/Fruits/cookie_still.png');
    add(
      SpriteComponent(
        sprite: cookieSprite,
        position: Vector2(-50, 50),
        size: Vector2.all(32),
        anchor: Anchor.center,
      ),
    );
  }

  // The display sits in the top-right corner; the text and cookie are
  // placed relative to it, so they move along when the screen size changes
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x, 0);
  }

  @override
  void update(double dt) {
    _scoreTextComponent.text = '${game.world1.player.money}';
  }
}
