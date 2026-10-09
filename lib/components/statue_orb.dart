import 'dart:ui';

import 'package:flame/components.dart';

import 'package:survivor_test/components/lob.dart';

// The orb the charged statue throws. It flies in an arc (see Lob) from the
// statue to its landing spot, calls onLanded there and disappears.
// PLACEHOLDER look: a purple circle until there's art for it.
class StatueOrb extends CircleComponent {
  StatueOrb({
    required Vector2 from,
    required Vector2 landingSpot,
    required void Function() onLanded,
  }) : super(
         radius: 12,
         position: landingSpot.clone(),
         anchor: Anchor.center,
         paint: Paint()..color = const Color(0xFFB57BFF),
       ) {
    add(
      Lob(
        from: from,
        onLanded: () {
          onLanded();
          removeFromParent();
        },
      ),
    );
  }
}
