import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:survivor_test/survivor_test.dart';

// A banner that slides down at the top of the screen during a run, e.g.
// "New character unlocked: Melee Lad!", stays for a moment and slides away.
// Start one with game.announceUnlock(); several are shown one after another.
class UnlockBanner extends PositionComponent
    with HasGameReference<SurvivorTest> {
  // ---- Tuning ----
  // How long the banner stays fully visible, in seconds
  static const double showDuration = 3;
  // How long sliding in (and out) takes, in seconds
  static const double slideDuration = 0.3;
  // Distance from the top of the screen while visible, in pixels
  // (below the seed display)
  static const double topMargin = 80;
  static const double padding = 12;
  static const Color textColor = Colors.amber;
  static const Color backgroundColor = Color.fromRGBO(0, 0, 0, 0.8);

  final String text;
  // Called once the banner has slid away (shows the next one, if any)
  final void Function() onFinished;
  UnlockBanner({required this.text, required this.onFinished})
    : super(anchor: Anchor.topCenter);

  double _time = 0;

  @override
  FutureOr<void> onLoad() {
    final label = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: const TextStyle(color: textColor, fontSize: 20),
      ),
      position: Vector2.all(padding),
    );
    size = label.size + Vector2.all(padding * 2);
    add(RectangleComponent(size: size, paint: Paint()..color = backgroundColor));
    add(label);
    _place();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_time >= showDuration + slideDuration * 2) {
      removeFromParent();
      return;
    }
    _place();
  }

  @override
  void onRemove() {
    onFinished();
    super.onRemove();
  }

  // Top centre of the screen; slides in from above at the start and back up
  // at the end
  void _place() {
    final double visible; // 0 = hidden above the screen, 1 = fully down
    if (_time < slideDuration) {
      visible = _time / slideDuration;
    } else if (_time < slideDuration + showDuration) {
      visible = 1;
    } else {
      visible = 1 - (_time - slideDuration - showDuration) / slideDuration;
    }
    final hiddenY = -size.y;
    position = Vector2(
      game.size.x / 2,
      hiddenY + (topMargin - hiddenY) * visible.clamp(0, 1),
    );
  }
}
