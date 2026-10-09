import 'package:flame/components.dart';

import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/soul_collector.dart';

// Which seed each upgrade room's tree drops
const Map<String, ItemType> roomSeeds = {
  'Health.tmx': ItemType.AppleSeed,
  'Stamina.tmx': ItemType.BananaSeed,
  'Damage.tmx': ItemType.CherrySeed,
};

// The special tree in each upgrade room. Enemies killed near it charge it up;
// once fully charged it drops the room's seed.
// Its position and size come from the "Tree" object in the room's map.
// The soul charging itself is shared with other collectors (SoulCollector).
class FruitTree extends SoulCollector {
  // ---- Tuning ----
  // How many kills near the tree it takes to drop the seed
  static const int killsToCharge = 10;
  // How close a kill must be to count, as a fraction of the room's width
  static const double chargeRangeOfRoomWidth = 0.25;

  final ItemType seedType;
  final Vector2 seedSpot;
  FruitTree({
    required super.position,
    required super.size,
    required this.seedType,
    required this.seedSpot,
  });

  @override
  int get soulsNeeded => killsToCharge;

  @override
  bool isInRange(Vector2 point) {
    final range = game.world1.level.width * chargeRangeOfRoomWidth;
    return absoluteCenter.distanceTo(point) <= range;
  }

  @override
  void onFullyCharged() {
    final seed = Item(position: seedSpot, type: seedType);
    game.world1.add(seed);
    game.world1.items.add(seed);
  }
}
