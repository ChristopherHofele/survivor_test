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
      position: Vector2(game.size.x - 100, 50),
    );
    add(_scoreTextComponent);

    final cookieSprite = await game.loadSprite('Items/Fruits/cookie_still.png');
    add(
      SpriteComponent(
        sprite: cookieSprite,
        position: Vector2(game.size.x - 50, 50),
        size: Vector2.all(32),
        anchor: Anchor.center,
      ),
    );
  }

  @override
  void update(double dt) {
    _scoreTextComponent.text = '${game.world1.player.money}';
  }
}
