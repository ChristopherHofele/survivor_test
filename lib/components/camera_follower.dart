import 'dart:math' show exp;

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/survivor_test.dart';

// Moves the camera with the player and keeps it inside the map.
// Normally the camera sits exactly on the player. When a sprint starts, the
// camera falls behind for a moment and then catches up, which makes the
// sprint feel faster.
//
// Near the map edges the camera stops at the edge. The lag is worked out
// from the point the camera is *allowed* to show, so it only builds up
// while the camera can actually move.
class CameraFollower extends Component with HasGameReference<SurvivorTest> {
  // ---- Tuning ----
  // How long after a sprint starts the camera is held back, in seconds
  static const double lagDuration = 1.5;
  // How strongly the camera is held back at the very start of a sprint:
  // 1 = the camera doesn't move at all, 0 = no lag
  static const double lagStrength = 0.8;
  // How fast the camera catches up again: higher = snappier
  static const double catchUpSpeed = 5;
  // The furthest the camera may fall behind, as a share of the visible
  // screen height (so the player never runs off the screen)
  static const double maxLagScreenShare = 0.25;
  // If the player moves further than this in one frame (e.g. a teleport),
  // the camera jumps straight to them instead of lagging, in pixels
  static const double jumpDistance = 100;

  final Player player;
  CameraFollower({required this.player});

  // Where the camera centre may be. Set by the Level whenever the screen
  // size changes.
  Rectangle bounds = Rectangle.fromLTRB(0, 0, 0, 0);

  // How far the camera is from where it would like to be
  final Vector2 _offset = Vector2.zero();
  // Where the camera wanted to be last frame (null = not placed yet)
  Vector2? _lastTarget;
  // Counts down from lagDuration after a sprint starts
  double _lagTimeLeft = 0;
  bool _wasSprinting = false;

  @override
  void update(double dt) {
    super.update(dt);

    // The point the camera would like to show: the player, pushed back
    // inside the map limits
    final target = _clampToBounds(player.position.clone());

    final isSprinting =
        player.isDashing && player.canDash && !player.velocity.isZero();
    if (isSprinting && !_wasSprinting) {
      _lagTimeLeft = lagDuration;
    }
    _wasSprinting = isSprinting;

    final lastTarget = _lastTarget;
    if (lastTarget == null) {
      // First frame in this room: start right on the player
      _offset.setZero();
    } else {
      final moved = target - lastTarget;
      if (moved.length > jumpDistance) {
        _offset.setZero();
      } else if (_lagTimeLeft > 0) {
        // Hold the camera back by part of the player's movement. The hold
        // is strongest when the sprint starts and fades out.
        final hold = lagStrength * (_lagTimeLeft / lagDuration);
        _offset.sub(moved * hold);
      }
    }
    _lagTimeLeft = (_lagTimeLeft - dt).clamp(0, lagDuration);

    // Catch up: the gap shrinks a bit every frame
    _offset.scale(exp(-catchUpSpeed * dt));

    // Never fall too far behind
    final visibleHeight = game.size.y / game.camera.viewfinder.zoom;
    final maxLag = visibleHeight * maxLagScreenShare;
    if (_offset.length > maxLag) {
      _offset.scaleTo(maxLag);
    }

    // Move the camera, but never past the map edges. If the edge cut the
    // lag short, forget the part that was cut so it can't build up out of
    // sight.
    final cameraPosition = _clampToBounds(target + _offset);
    _offset.setFrom(cameraPosition - target);
    game.camera.viewfinder.position = cameraPosition;
    _lastTarget = target;
  }

  Vector2 _clampToBounds(Vector2 point) {
    point.x = point.x.clamp(bounds.left, bounds.right);
    point.y = point.y.clamp(bounds.top, bounds.bottom);
    return point;
  }
}
