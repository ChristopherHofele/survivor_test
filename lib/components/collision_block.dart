import 'package:flame/components.dart';

enum ShopType { NoShop, HealthShop, StaminaShop, DamageShop }

class CollisionBlock extends PositionComponent {
  ShopType shopType;
  CollisionBlock({position, size, this.shopType = ShopType.NoShop})
    : super(position: position, size: size) {}
}
