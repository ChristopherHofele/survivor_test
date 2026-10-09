import 'package:flame/components.dart';

// Makes its parent fly in an arc, like something thrown, from the point
// "from" to where the parent was placed. Usage: create the thing at its
// landing spot as usual, then add a Lob to it:
//   fruit.add(Lob(from: statueCenter, onLanded: ...));
// While flying it's drawn above everything; it removes itself after landing.
class Lob extends Component with ParentIsA<PositionComponent> {
  // ---- Tuning ----
  // How long a throw takes, in seconds
  static const double defaultFlightTime = 1.2;
  // How high the arc goes at its highest point, in pixels
  static const double defaultArcHeight = 150;

  final Vector2 from;
  final double flightTime;
  final double arcHeight;
  final void Function()? onLanded;
  Lob({
    required this.from,
    this.flightTime = defaultFlightTime,
    this.arcHeight = defaultArcHeight,
    this.onLanded,
  });

  late final Vector2 _start;
  late final Vector2 _end;
  late final int _priorityOnGround;
  double _timeFlown = 0;

  @override
  void onMount() {
    super.onMount();
    // The parent was placed at its landing spot, so that's the end point.
    // The start is shifted so that the parent's centre begins at "from".
    _end = parent.position.clone();
    _start = _end + (from - parent.absoluteCenter);
    parent.position = _start.clone();
    _priorityOnGround = parent.priority;
    parent.priority = 3;
  }

  @override
  void update(double dt) {
    _timeFlown += dt;
    // How far along the flight is: 0 at the start, 1 at the landing spot
    final progress = (_timeFlown / flightTime).clamp(0.0, 1.0);
    // The point on the ground below moves in a straight line...
    final groundPoint = _start + (_end - _start) * progress;
    // ...and the parent is drawn above it: 0 at both ends, arcHeight halfway
    final height = arcHeight * 4 * progress * (1 - progress);
    parent.position = groundPoint - Vector2(0, height);

    if (progress >= 1) {
      parent.position = _end;
      parent.priority = _priorityOnGround;
      onLanded?.call();
      removeFromParent();
    }
    super.update(dt);
  }
}
