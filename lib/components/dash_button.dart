import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:survivor_test/survivor_test.dart';

class DashButton extends SpriteComponent
    with HasGameReference<SurvivorTest>, TapCallbacks {
  DashButton();

  final margin = 64;
  final int buttonSize = 64;

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('HUD/DashButton.png'));
    position = Vector2(
      game.size.x - game.size.x + margin + buttonSize,
      game.size.y - margin - buttonSize,
    );
    priority = 10;
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.player.isDashing = true;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.player.isDashing = false;
    super.onTapUp(event);
  }
}
