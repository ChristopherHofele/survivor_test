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

  List<Vector2> extendedCorners = [];

  @override
  FutureOr<void> onLoad() {
    switch (cornerType) {
      case CornerType.Left:
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
      case CornerType.Top:
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
      case CornerType.Right:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
      case CornerType.Bottom:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
      case CornerType.TopLeft:
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
      case CornerType.TopRight:
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y));
      case CornerType.BottomRight:
        extendedCorners.add(Vector2(position.x, position.y + size.y));
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
      case CornerType.BottomLeft:
        extendedCorners.add(Vector2(position.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y));
        extendedCorners.add(Vector2(position.x + size.x, position.y + size.y));
      default:
        extendedCorners = [];
    }
    return super.onLoad();
  }
}
