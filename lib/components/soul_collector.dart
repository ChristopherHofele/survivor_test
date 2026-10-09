import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'package:survivor_test/components/soul.dart';
import 'package:survivor_test/survivor_test.dart';

// Something that is charged up by the souls of nearby kills and does
// something once it's full (the fruit trees and the lake statue).
// It shows its progress (e.g. "3/10") above itself.
//
// A class that extends this decides:
//  - soulsNeeded: how many souls it takes
//  - isInRange: which kills count
//  - onFullyCharged: what happens when it's full
//  - isCollecting (optional): whether it accepts souls right now
abstract class SoulCollector extends PositionComponent
    with HasGameReference<SurvivorTest> {
  SoulCollector({required super.position, required super.size});

  int get soulsNeeded;
  bool isInRange(Vector2 point);
  void onFullyCharged();
  // Collectors that are only sometimes active (like the statue) override this.
  // While it's false, no souls come and the progress text is hidden.
  bool get isCollecting => true;

  int charge = 0;
  // Souls that are still flying here. They are counted so the collector
  // doesn't take more kills than it needs while souls are on their way.
  int _soulsOnTheWay = 0;
  late TextComponent _progressText;

  bool get isFullyCharged => charge >= soulsNeeded;
  String get _progressLabel => '$charge/$soulsNeeded';

  @override
  FutureOr<void> onLoad() {
    _progressText = TextComponent(
      text: isCollecting ? _progressLabel : '',
      anchor: Anchor.bottomCenter,
      position: Vector2(size.x / 2, -4),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 14, color: Color(0xFFFFFFFF)),
      ),
    );
    add(_progressText);
    return super.onLoad();
  }

  // Whether a kill at this point should send a soul here
  bool canAbsorbAt(Vector2 point) {
    if (!isCollecting) return false;
    if (charge + _soulsOnTheWay >= soulsNeeded) return false;
    return isInRange(point);
  }

  // Called by an enemy that died in range
  void sendSoulFrom(Vector2 point) {
    _soulsOnTheWay += 1;
    game.world1.add(Soul(position: point.clone(), target: this));
  }

  // Called by a soul when it arrives
  void receiveSoul() {
    _soulsOnTheWay -= 1;
    if (isFullyCharged) return;
    charge += 1;
    refreshProgress();
    if (isFullyCharged) {
      onFullyCharged();
    }
  }

  // Starts counting from 0 again
  void resetCharge() {
    charge = 0;
    refreshProgress();
  }

  // Updates the progress text, e.g. after isCollecting changed
  void refreshProgress() {
    _progressText.text = isCollecting ? _progressLabel : '';
  }
}
