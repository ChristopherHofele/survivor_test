import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/soul.dart';
import 'package:survivor_test/survivor_test.dart';

// Which seed each upgrade room's tree drops
const Map<String, ItemType> roomSeeds = {
  'Health.tmx': ItemType.AppleSeed,
  'Stamina.tmx': ItemType.BananaSeed,
  'Damage.tmx': ItemType.CherrySeed,
};

// The special tree in each upgrade room. Enemies killed near it charge it up;
// once fully charged it drops the room's seed.
// Its position and size come from the "Tree" object in the room's map.
class FruitTree extends PositionComponent with HasGameReference<SurvivorTest> {
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

  int charge = 0;
  // Souls that are still flying here. They are counted so the tree doesn't
  // take more kills than it needs while souls are on their way.
  int _soulsOnTheWay = 0;
  late TextComponent _progressText;

  bool get isFullyCharged => charge >= killsToCharge;
  String get _progressLabel => '$charge/$killsToCharge';

  @override
  FutureOr<void> onLoad() {
    _progressText = TextComponent(
      text: _progressLabel,
      anchor: Anchor.bottomCenter,
      position: Vector2(size.x / 2, -4),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 14, color: Color(0xFFFFFFFF)),
      ),
    );
    add(_progressText);
    return super.onLoad();
  }

  // Whether a kill at this point should send a soul to the tree
  bool canAbsorbAt(Vector2 point) {
    if (charge + _soulsOnTheWay >= killsToCharge) return false;
    final range = game.world1.level.width * chargeRangeOfRoomWidth;
    return absoluteCenter.distanceTo(point) <= range;
  }

  // Called by an enemy that died nearby
  void sendSoulFrom(Vector2 point) {
    _soulsOnTheWay += 1;
    game.world1.add(Soul(position: point.clone(), tree: this));
  }

  // Called by a soul when it reaches the tree
  void receiveSoul() {
    _soulsOnTheWay -= 1;
    if (isFullyCharged) return;
    charge += 1;
    _progressText.text = _progressLabel;
    if (isFullyCharged) {
      _dropSeed();
    }
  }

  void _dropSeed() {
    final seed = Item(position: seedSpot, type: seedType);
    game.world1.add(seed);
    game.world1.items.add(seed);
  }
}
