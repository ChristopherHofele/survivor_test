import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:survivor_test/survivor_test.dart';

class DashButton extends SpriteGroupComponent
    with HasGameReference<SurvivorTest>, TapCallbacks {
  DashButton() : super(size: Vector2(64, 64));

  final margin = 64;
  final int buttonSize = 64;

  late final Sprite empty;
  late final Sprite quarter;
  late final Sprite half;
  late final Sprite threeQuarter;
  late final Sprite full;

  @override
  FutureOr<void> onLoad() {
    _loadSprites();
    position = Vector2(
      game.size.x - game.size.x + 2 * margin + buttonSize,
      game.size.y - margin - buttonSize,
    );
    sprites = {
      'zero': empty,
      'twentyfive': quarter,
      'fifty': half,
      'seventyfive': threeQuarter,
      'hundred': full,
    };
    priority = 10;
    size *= 1.3;
    current = 'zero';
    return super.onLoad();
  }

  @override
  void update(double dt) {
    switch (game.player.stamina / 100) {
      case 1:
        current = 'hundred';
        break;
      case >= 0.75:
        current = 'seventyfive';
        break;

      case >= 0.5:
        current = 'fifty';
        break;
      case >= 0.25:
        current = 'twentyfive';
        break;
      default:
        current = 'zero';
    }
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

  void _loadSprites() {
    empty = Sprite(game.images.fromCache('HUD/DashButton0.png'));
    quarter = Sprite(game.images.fromCache('HUD/DashButton25.png'));
    half = Sprite(game.images.fromCache('HUD/DashButton50.png'));
    threeQuarter = Sprite(game.images.fromCache('HUD/DashButton75.png'));
    full = Sprite(game.images.fromCache('HUD/DashButton100.png'));
  }
}
