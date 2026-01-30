import 'dart:async';

import 'package:flame/components.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/survivor_test.dart';

enum InteractionType { None, HealthShop, StaminaShop, DamageShop, Portal }

enum BlockType {
  Left,
  TopLeft,
  Top,
  TopRight,
  Right,
  BottomRight,
  Bottom,
  BottomLeft,
  NoCorners,
  Irrelevant,
}

class CollisionBlock extends PositionComponent
    with HasGameReference<SurvivorTest> {
  InteractionType interactionType;
  BlockType blockType;
  String destinationName;
  CollisionBlock({
    position,
    size,
    this.interactionType = InteractionType.None,
    this.blockType = BlockType.Irrelevant,
    this.destinationName = '',
  }) : super(position: position, size: size);

  int entryCost = 0;
  Vector2 teleportCoordinates = Vector2.zero();
  List<Vector2> extendedCorners = [];

  @override
  FutureOr<void> onLoad() {
    entryCost = game.doorPrices[game.doorsOpened];
    print(entryCost);
    switch (blockType) {
      case BlockType.NoCorners:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        break;
      case BlockType.Left:
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        break;
      case BlockType.Top:
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        break;
      case BlockType.Right:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        break;
      case BlockType.Bottom:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        break;
      case BlockType.TopLeft:
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        break;
      case BlockType.TopRight:
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y));
        break;
      case BlockType.BottomRight:
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        break;
      case BlockType.BottomLeft:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        break;
      default:
        extendedCorners = [];
    }
    if (interactionType == InteractionType.Portal) {
      switch (destinationName) {
        case 'Level1.tmx':
          teleportCoordinates = Vector2(960, 1024);
          break;
        case 'Health.tmx':
          teleportCoordinates = Vector2(128, 496);
          break;
        case 'Stamina.tmx':
          teleportCoordinates = Vector2(690, 96);
          break;
        case 'Damage.tmx':
          teleportCoordinates = Vector2(1120, 432);
          break;
        default:
      }
    }
    switch (interactionType) {
      case InteractionType.HealthShop:
      case InteractionType.StaminaShop:
      case InteractionType.DamageShop:
        Item fruit = Item(
          position: position,
          worldName: game.world1.tileMapName,
          worth: 5,
        );
        game.world1.add(fruit);
        game.world1.items.add(fruit);
        break;
      default:
    }
    return super.onLoad();
  }
}
