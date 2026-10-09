import 'dart:ui';

import 'package:flame/components.dart';

// The orb the charged statue throws. It flies in an arc from the statue to
// its target and calls onLanded when it arrives.
// PLACEHOLDER look: a purple circle until there's art for it.
class StatueOrb extends CircleComponent {
  // ---- Tuning ----
  // How long the throw takes, in seconds
  static const double flightTime = 1.2;
  // How high the arc goes at its highest point, in pixels
  static const double arcHeight = 150;

  final Vector2 start;
  final Vector2 target;
  final void Function() onLanded;
  StatueOrb({required this.start, required this.target, required this.onLanded})
    : super(
        radius: 12,
        position: start.clone(),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFB57BFF),
        // Drawn above everything else, since it flies over the level
        priority: 3,
      );

  double _timeFlown = 0;

  @override
  void update(double dt) {
    _timeFlown += dt;
    // How far along the flight is: 0 at the statue, 1 at the target
    final progress = (_timeFlown / flightTime).clamp(0.0, 1.0);
    // The point on the ground below the orb moves in a straight line...
    final groundPoint = start + (target - start) * progress;
    // ...and the orb is drawn above it: 0 at both ends, arcHeight halfway
    final height = arcHeight * 4 * progress * (1 - progress);
    position = groundPoint - Vector2(0, height);

    if (progress >= 1) {
      onLanded();
      removeFromParent();
    }
    super.update(dt);
  }
}
