import 'package:flutter/material.dart';

import 'package:flame/components.dart';

import 'package:survivor_test/components/fruit_tree.dart';
import 'package:survivor_test/components/items.dart';
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
      // Upgrade rooms: the exit needs the room's seed
      case 'Health.tmx':
      case 'Stamina.tmx':
      case 'Damage.tmx':
        _addRequiredSeedComponent(roomSeeds[worldName]!);
        break;
      case 'Bossroom.tmx':
        _addRequiredFruitComponent('Strawberry');
        break;
      default:
    }
  }

  void _addRequiredSeedComponent(ItemType seed) {
    _requiredFruitComponent = SpriteComponent.fromImage(
      game.images.fromCache(itemImagePath(seed)),
      position: position,
      // Seed images are 64 x 64; shown at the same size as the fruit icons
      size: Vector2.all(32),
      anchor: Anchor.center,
    );
    game.world1.add(_requiredFruitComponent);
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
