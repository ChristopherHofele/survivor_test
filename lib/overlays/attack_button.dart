import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:survivor_test/survivor_test.dart';

class AttackButton extends SpriteGroupComponent
    with HasGameReference<SurvivorTest>, TapCallbacks {
  AttackButton() : super(size: Vector2(64, 64));

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
      game.size.x - game.size.x + margin,
      game.size.y - 1.5 * margin - buttonSize,
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
    switch (game.player.attackCooldown / game.player.maxAttackCooldown) {
      case <= 0:
        current = 'hundred';
        break;
      case <= 0.25:
        current = 'seventyfive';
        break;

      case <= 0.5:
        current = 'fifty';
        break;
      case <= 0.75:
        current = 'twentyfive';
        break;
      case <= 1:
        current = 'zero';
        break;
      default:
    }
    super.update(dt);
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

  void _loadSprites() {
    empty = Sprite(game.images.fromCache('HUD/AttackButton0.png'));
    quarter = Sprite(game.images.fromCache('HUD/AttackButton25.png'));
    half = Sprite(game.images.fromCache('HUD/AttackButton50.png'));
    threeQuarter = Sprite(game.images.fromCache('HUD/AttackButton75.png'));
    full = Sprite(game.images.fromCache('HUD/AttackButton100.png'));
  }
}
