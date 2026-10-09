import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

// The zone on the ground created by the statue's orb. An enemy killed inside
// it is charged. It does nothing to the player and has no hitbox.
// PLACEHOLDER look: a softly pulsing purple circle until there's art for it.
class ChargeZone extends CircleComponent {
  ChargeZone({required Vector2 center, required double diameter})
    : super(
        radius: diameter / 2,
        position: center,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFB57BFF),
        // Same priority as the map: drawn on the ground, below enemies
        priority: 0,
      );

  @override
  Future<void> onLoad() {
    opacity = 0.35;
    add(
      OpacityEffect.to(
        0.15,
        EffectController(duration: 0.8, alternate: true, infinite: true),
      ),
    );
    return super.onLoad();
  }

  bool isInside(Vector2 point) => absoluteCenter.distanceTo(point) <= radius;
}
