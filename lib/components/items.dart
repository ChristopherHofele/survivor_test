import 'dart:async';

import 'package:flame/components.dart';

import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/survivor_test.dart';

enum ItemType {
  Cookie,
  Key,
  Apple,
  Bananas,
  Cherries,
  Strawberry,
  AppleSeed,
  BananaSeed,
  CherrySeed,
}

// The image for each item type (also used by the HUD and door signs)
String itemImagePath(ItemType type) => switch (type) {
  ItemType.Cookie => 'Items/Fruits/cookie.png',
  ItemType.Key => 'Items/Fruits/Key.png',
  ItemType.Apple => 'Items/Fruits/Apple.png',
  ItemType.Bananas => 'Items/Fruits/Bananas.png',
  ItemType.Cherries => 'Items/Fruits/Cherries.png',
  ItemType.Strawberry => 'Items/Fruits/Strawberry.png',
  ItemType.AppleSeed => 'Apple_Seed.png',
  ItemType.BananaSeed => 'Banana_Seed.png',
  ItemType.CherrySeed => 'Cherry_Seed.png',
};

class Item extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest> {
  final ItemType type;
  // True for fruits offered by the lake statue
  final bool isGift;
  Item({required position, required this.type, this.isGift = false})
    : super(position: position - Vector2.all(25), size: Vector2.all(50));

  // Money the player gets for picking this item up
  int get worth => switch (type) {
    ItemType.Cookie => 1,
    ItemType.Key => 0,
    ItemType.Apple || ItemType.Bananas || ItemType.Cherries => 5,
    ItemType.Strawberry => 10,
    ItemType.AppleSeed || ItemType.BananaSeed || ItemType.CherrySeed => 0,
  };

  @override
  FutureOr<void> onLoad() {
    final Vector2 frameSize;
    switch (type) {
      case ItemType.Cookie:
        frameSize = Vector2.all(32);
      case ItemType.Key:
        frameSize = Vector2(10, 27);
        size = frameSize.clone();
      case ItemType.Apple:
      case ItemType.Bananas:
      case ItemType.Cherries:
      case ItemType.Strawberry:
        frameSize = Vector2.all(32);
        position += Vector2.all(9);
      case ItemType.AppleSeed:
      case ItemType.BananaSeed:
      case ItemType.CherrySeed:
        // Seeds are single 64 x 64 images, drawn at the item's size
        frameSize = Vector2.all(64);
        position += Vector2.all(9);
    }
    animation = spriteSheetAnimation(game.images, itemImagePath(type), frameSize);
    return super.onLoad();
  }
}
