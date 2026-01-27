import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:survivor_test/survivor_test.dart';

class AttackButton extends SpriteComponent
    with HasGameReference<SurvivorTest>, TapCallbacks {
  AttackButton();

  final margin = 64;
  final int buttonSize = 64;

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('HUD/AttackButton.png'));
    position = Vector2(
      game.size.x - game.size.x + margin,
      game.size.y - 1.5 * margin - buttonSize,
    );
    priority = 10;
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.player.isAttacking = true;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.player.isAttacking = false;
    super.onTapUp(event);
  }
}
