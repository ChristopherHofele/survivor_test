import 'package:flutter/material.dart';

import 'package:flame/components.dart';

import 'package:survivor_test/survivor_test.dart';

class DoorPriceDisplay extends PositionComponent
    with HasGameReference<SurvivorTest> {
  DoorPriceDisplay({
    required position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
  }) : super(position: position);

  late TextComponent _priceTextComponent;

  @override
  Future<void> onLoad() async {
    _priceTextComponent = TextComponent(
      text: '${game.doorPrices[game.doorsOpened]}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Color.fromRGBO(255, 255, 255, 1),
        ),
      ),
      anchor: Anchor.center,
      position: position,
    );
    game.world1.add(_priceTextComponent);
  }

  @override
  void update(double dt) {
    _priceTextComponent.text = '${game.doorPrices[game.doorsOpened]}';
    super.update(dt);
  }
}
