import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/survivor_test.dart';

// Which fruit the statue gives for each planted seed
const Map<ItemType, ItemType> seedFruits = {
  ItemType.AppleSeed: ItemType.Apple,
  ItemType.BananaSeed: ItemType.Bananas,
  ItemType.CherrySeed: ItemType.Cherries,
};

// The statue in the lake in Level 1. Touching the lake ("DropOff" areas in
// the map) plants every seed the player carries; for each seed the statue
// offers the matching fruit at the "Gift" spot.
class LakeStatue extends Component with HasGameReference<SurvivorTest> {
  // Distance between fruits when several are waiting at the gift spot
  static const double giftSpacing = 40;

  final List<PositionComponent> dropOffZones;
  final Vector2 giftSpot;
  LakeStatue({required this.dropOffZones, required this.giftSpot});

  // Fruits lying at the gift spot. A slot is null once its fruit was taken,
  // so new fruits fill gaps instead of landing on top of another fruit.
  final List<Item?> _giftSlots = [];

  @override
  FutureOr<void> onLoad() {
    // Fruits that weren't taken before leaving Level 1 are offered again
    for (final fruit in game.waitingGifts) {
      _placeGift(fruit);
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    final player = game.player;
    if (player.seeds.isNotEmpty &&
        dropOffZones.any((zone) => checkCollision(player, zone))) {
      _plantSeeds();
    }
    super.update(dt);
  }

  void _plantSeeds() {
    final player = game.player;
    for (final seed in player.seeds) {
      game.plantedSeeds.add(seed);
      final fruit = seedFruits[seed]!;
      game.waitingGifts.add(fruit);
      _placeGift(fruit);
    }
    player.seeds.clear();
    _playPlantingEffect();
  }

  void _placeGift(ItemType fruit) {
    int slot = _giftSlots.indexOf(null);
    if (slot == -1) {
      slot = _giftSlots.length;
      _giftSlots.add(null);
    }
    final gift = Item(
      position: giftSpot + Vector2(slot * giftSpacing, 0),
      type: fruit,
      isGift: true,
    );
    _giftSlots[slot] = gift;
    game.world1.add(gift);
    game.world1.items.add(gift);
  }

  // Called by the player when picking up one of the statue's fruits
  void giftTaken(Item gift) {
    final slot = _giftSlots.indexOf(gift);
    if (slot != -1) {
      _giftSlots[slot] = null;
    }
    game.waitingGifts.remove(gift.type);
  }

  // PLACEHOLDER until the statue art is ready (eyes flash + orbiting orb in
  // the fruit's colour): briefly flashes the whole lake area white
  void _playPlantingEffect() {
    double left = double.infinity, top = double.infinity;
    double right = -double.infinity, bottom = -double.infinity;
    for (final zone in dropOffZones) {
      if (zone.x < left) left = zone.x;
      if (zone.y < top) top = zone.y;
      if (zone.x + zone.width > right) right = zone.x + zone.width;
      if (zone.y + zone.height > bottom) bottom = zone.y + zone.height;
    }
    final flash = RectangleComponent(
      position: Vector2(left, top),
      size: Vector2(right - left, bottom - top),
      paint: Paint()..color = const Color(0x99FFFFFF),
    );
    flash.add(
      OpacityEffect.fadeOut(EffectController(duration: 0.6))
        ..onComplete = flash.removeFromParent,
    );
    game.world1.add(flash);
  }
}
