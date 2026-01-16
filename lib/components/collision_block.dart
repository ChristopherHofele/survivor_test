import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent {
  bool isShop;
  CollisionBlock({position, size, this.isShop = false})
    : super(position: position, size: size) {}
}
