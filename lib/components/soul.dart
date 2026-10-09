import 'dart:async';

import 'package:flame/components.dart';

import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/soul_collector.dart';
import 'package:survivor_test/survivor_test.dart';

// Spawned when an enemy dies near something that collects souls (like a fruit
// tree). It flies there and charges it on arrival.
// It has no hitbox, so nothing can hit or block it.
class Soul extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest> {
  // How fast the soul flies to its target, in pixels per second
  static const double flySpeed = 100;

  final SoulCollector target;
  Soul({required super.position, required this.target})
    : super(size: Vector2.all(32), anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() {
    // Same priority as the map (0): souls are added after the map, so they're
    // drawn on top of it, but behind enemies and the player (priority 1)
    priority = 0;
    animation = spriteSheetAnimation(
      game.images,
      'Soul_Flying.png',
      Vector2.all(32),
    );
    return super.onLoad();
  }

  @override
  void update(double dt) {
    final toTarget = target.absoluteCenter - position;
    final step = flySpeed * dt;
    if (toTarget.length <= step) {
      target.receiveSoul();
      removeFromParent();
    } else {
      position += toTarget.normalized() * step;
    }
    super.update(dt);
  }
}
