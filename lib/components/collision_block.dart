import 'dart:async';

import 'package:flame/components.dart';

enum ShopType { NoShop, HealthShop, StaminaShop, DamageShop }

enum CornerType {
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

class CollisionBlock extends PositionComponent {
  ShopType shopType;
  CornerType cornerType;
  String destinationName;
  CollisionBlock({
    position,
    size,
    this.shopType = ShopType.NoShop,
    this.cornerType = CornerType.Irrelevant,
    this.destinationName = '',
  }) : super(position: position, size: size);

  Vector2 teleportCoordinates = Vector2.zero();
  List<Vector2> extendedCorners = [];

  @override
  FutureOr<void> onLoad() {
    switch (cornerType) {
      case CornerType.NoCorners:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        break;
      case CornerType.Left:
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        break;
      case CornerType.Top:
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        break;
      case CornerType.Right:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        break;
      case CornerType.Bottom:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        break;
      case CornerType.TopLeft:
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        break;
      case CornerType.TopRight:
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y));
        break;
      case CornerType.BottomRight:
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        break;
      case CornerType.BottomLeft:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        break;
      default:
        extendedCorners = [];
    }
    switch (destinationName) {
      case 'Level1.tmx':
        teleportCoordinates = Vector2(993, 993);
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
    return super.onLoad();
  }
}
