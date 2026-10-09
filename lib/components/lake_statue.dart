import 'dart:async';
import 'dart:math' show Random;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/charge_zone.dart';
import 'package:survivor_test/components/fruit_tree.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/lob.dart';
import 'package:survivor_test/components/soul_collector.dart';
import 'package:survivor_test/components/statue_orb.dart';

// Which fruit the statue gives for each planted seed
const Map<ItemType, ItemType> seedFruits = {
  ItemType.AppleSeed: ItemType.Apple,
  ItemType.BananaSeed: ItemType.Bananas,
  ItemType.CherrySeed: ItemType.Cherries,
};

// The statue in the lake in Level 1.
//  - Touching the lake ("DropOff" areas in the map) plants every seed the
//    player carries; for each seed the statue throws the matching fruit to
//    the "Gift" spot.
//  - Once one seed of each kind has been planted, the statue activates:
//    every kill in Level 1 sends it a soul, and Level 1 is locked until the
//    key has been collected.
//  - Fully charged, it throws an orb to one of the "ZoneSpot" points, which
//    creates a zone. An enemy killed inside the zone revives as a stronger
//    charged version, which drops the key when killed.
// Its position and size are the area around the lake (all DropOff areas).
class LakeStatue extends SoulCollector {
  // ---- Tuning ----
  // How many souls it takes to fully charge the active statue
  static const int soulsToCharge = 2;
  // Distance between fruits when several are waiting at the gift spot
  static const double giftSpacing = 40;
  // Size of the zone the orb creates: about 3 times the character (64)
  static const double zoneDiameter = 192;

  final List<PositionComponent> dropOffZones;
  final Vector2 giftSpot;
  final List<Vector2> zoneSpots;
  LakeStatue({
    required super.position,
    required super.size,
    required this.dropOffZones,
    required this.giftSpot,
    required this.zoneSpots,
  });

  final _random = Random();
  // The zone on the ground, while there is one
  ChargeZone? chargeZone;

  // True while the statue collects souls
  bool isActive = false;
  // True from activation until the key has been collected: nobody leaves
  // Level 1 in the meantime
  bool isLockingLevel = false;

  // Fruits lying at the gift spot. A slot is null once its fruit was taken,
  // so new fruits fill gaps instead of landing on top of another fruit.
  final List<Item?> _giftSlots = [];

  @override
  int get soulsNeeded => soulsToCharge;

  @override
  bool get isCollecting => isActive;

  // The whole level counts: Level 1 is one big circle around the lake
  @override
  bool isInRange(Vector2 point) => true;

  @override
  void onFullyCharged() {
    isActive = false;
    refreshProgress();
    _throwOrb();
  }

  // Throws the orb to a random zone spot (or the gift spot if the map has
  // no zone spots); the zone appears where it lands
  void _throwOrb() {
    final landingSpot = zoneSpots.isEmpty
        ? giftSpot
        : zoneSpots[_random.nextInt(zoneSpots.length)];
    game.world1.add(
      StatueOrb(
        from: absoluteCenter,
        landingSpot: landingSpot,
        onLanded: () => _createZone(landingSpot),
      ),
    );
  }

  void _createZone(Vector2 spot) {
    chargeZone = ChargeZone(center: spot.clone(), diameter: zoneDiameter);
    game.world1.add(chargeZone!);
  }

  bool isInChargeZone(Vector2 point) => chargeZone?.isInside(point) ?? false;

  // Called by an enemy that was killed inside the zone (it then revives as
  // its charged version): the zone has done its job and disappears
  void chargeZoneUsed() {
    chargeZone?.removeFromParent();
    chargeZone = null;
  }

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
      _placeGift(fruit, thrown: true);
    }
    player.seeds.clear();
    _playPlantingEffect();
    if (!isLockingLevel && game.plantedSeeds.containsAll(roomSeeds.values)) {
      _activate();
    }
  }

  void _activate() {
    // The next activation needs one seed of each kind again
    game.plantedSeeds.clear();
    isActive = true;
    isLockingLevel = true;
    resetCharge();
  }

  // Called by the player when picking up the key: Level 1 opens up again
  void keyCollected() {
    isLockingLevel = false;
  }

  // thrown: the fruit flies from the statue to its spot (when planting).
  // Otherwise it's simply placed there (fruits waiting from earlier).
  void _placeGift(ItemType fruit, {bool thrown = false}) {
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
    if (thrown) {
      // It can only be picked up once it has landed
      gift.add(
        Lob(from: absoluteCenter, onLanded: () => game.world1.items.add(gift)),
      );
    } else {
      game.world1.items.add(gift);
    }
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
    final flash = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0x99FFFFFF),
    );
    flash.add(
      OpacityEffect.fadeOut(EffectController(duration: 0.6))
        ..onComplete = flash.removeFromParent,
    );
    add(flash);
  }
}
