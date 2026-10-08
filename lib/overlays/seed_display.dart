import 'dart:async';

import 'package:flame/components.dart';

import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/survivor_test.dart';

// Shows the seeds the player is carrying at the top of the screen,
// to the right of where the key appears. Each seed has its own fixed slot,
// so the icons don't jump around when one is planted.
class SeedDisplay extends PositionComponent with HasGameReference<SurvivorTest> {
  static const List<ItemType> _seedOrder = [
    ItemType.AppleSeed,
    ItemType.BananaSeed,
    ItemType.CherrySeed,
  ];
  static const double _iconSize = 32;
  static const double _spacing = 36;

  final Map<ItemType, SpriteComponent> _icons = {};

  @override
  FutureOr<void> onLoad() {
    for (int i = 0; i < _seedOrder.length; i++) {
      final seed = _seedOrder[i];
      final icon = SpriteComponent.fromImage(
        game.images.fromCache(itemImagePath(seed)),
        size: Vector2.all(_iconSize),
        anchor: Anchor.center,
        position: Vector2(40 + i * _spacing, 50),
      );
      _icons[seed] = icon;
      add(icon);
    }
    return super.onLoad();
  }

  // Starts at the top centre of the screen and moves along when it resizes
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x / 2, 0);
  }

  @override
  void update(double dt) {
    // Carried seeds are fully visible, the others are hidden
    for (final entry in _icons.entries) {
      entry.value.opacity = game.player.seeds.contains(entry.key) ? 1 : 0;
    }
    super.update(dt);
  }
}
