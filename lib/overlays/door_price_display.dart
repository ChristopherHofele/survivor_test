import 'package:flutter/material.dart';

import 'package:flame/components.dart';

import 'package:survivor_test/survivor_test.dart';

class DoorPriceDisplay extends PositionComponent
    with HasGameReference<SurvivorTest> {
  String worldName;
  String destinationName;
  DoorPriceDisplay({
    required position,
    required this.worldName,
    required this.destinationName,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
  }) : super(position: position);

  late TextComponent _priceTextComponent;
  late SpriteComponent _requiredFruitComponent;
  bool priceLoaded = false;

  @override
  Future<void> onLoad() async {
    switch (worldName) {
      case 'Level1.tmx':
        if (destinationName == 'Bossroom.tmx') {
          _addRequiredFruitComponent('Key');
        } else {
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
          priceLoaded = true;
        }
        break;
      case 'Health.tmx':
        _addRequiredFruitComponent('Apple');
        break;
      case 'Stamina.tmx':
        _addRequiredFruitComponent('Bananas');
        break;
      case 'Damage.tmx':
        _addRequiredFruitComponent('Cherries');
        break;
      case 'Bossroom.tmx':
        _addRequiredFruitComponent('Strawberry');
        break;
      default:
    }
  }

  @override
  void update(double dt) {
    if (priceLoaded) {
      _priceTextComponent.text = '${game.doorPrices[game.doorsOpened]}';
    }
    super.update(dt);
  }

  void _addRequiredFruitComponent(String fruitName) {
    _requiredFruitComponent = SpriteComponent.fromImage(
      game.images.fromCache('Items/Fruits/${fruitName}_still.png'),
      position: position,
      anchor: Anchor.center,
    );
    game.world1.add(_requiredFruitComponent);
  }
}
