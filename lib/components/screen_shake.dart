import 'dart:math' show Random;

import 'package:flame/components.dart';

import 'package:survivor_test/survivor_test.dart';

// Shakes the whole screen for a moment by moving the camera's viewport (the
// frame the game is drawn into) back and forth. The shake gets weaker until
// it stops. Start one with game.shakeScreen().
class ScreenShake extends Component with HasGameReference<SurvivorTest> {
  // ---- Tuning ----
  // How long a shake lasts, in seconds
  static const double defaultDuration = 0.3;
  // How far the screen moves at the start of the shake, in pixels
  static const double defaultStrength = 8;

  final double duration;
  final double strength;
  ScreenShake({
    this.duration = defaultDuration,
    this.strength = defaultStrength,
  });

  final _random = Random();
  double _time = 0;

  @override
  void update(double dt) {
    _time += dt;
    if (_time >= duration) {
      removeFromParent();
      return;
    }
    // 1 at the start, 0 at the end: the shake fades out
    final fade = 1 - _time / duration;
    game.camera.viewport.position = Vector2(
      (_random.nextDouble() * 2 - 1) * strength * fade,
      (_random.nextDouble() * 2 - 1) * strength * fade,
    );
    super.update(dt);
  }

  // Put the screen back where it belongs when the shake ends
  @override
  void onRemove() {
    game.camera.viewport.position = Vector2.zero();
    super.onRemove();
  }
}
