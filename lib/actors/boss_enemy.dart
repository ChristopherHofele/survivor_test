import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/level.dart';
import 'package:survivor_test/survivor_test.dart';

class BossEnemy extends SpriteComponent
    with HasGameReference<SurvivorTest>, CollisionCallbacks {
  BossEnemy({required position})
    : super(position: position, size: Vector2.all(256), anchor: Anchor.center);

  late double health;
  late double attackCooldown;
  late double hitboxRadius;

  var random = Random();

  late final Player player;
  late final Level level;
  Vector2 lookDirection = Vector2.zero();

  @override
  FutureOr<void> onLoad() async {
    sprite = await Sprite.load('Boss.png');
    hitboxRadius = 128;
    add(
      CircleHitbox(
        radius: hitboxRadius,
        position: size / 2,
        anchor: Anchor.center,
        collisionType: CollisionType.active,
      ),
    );
    health = 200;

    return super.onLoad();
  }

  @override
  void update(double dt) {
    _handleHealth();
    super.update(dt);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Projectile && other.shooter == Shooter.Player) {
      health -= other.damage;
      other.hitCounter += 1;
      add(
        OpacityEffect.fadeOut(
          EffectController(alternate: true, duration: 0.1, repeatCount: 5),
        ),
      );
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _handleHealth() {
    if (health <= 0) {
      game.enemyCount -= 1;
      int worth = 10;
      Item loot = Item(
        position: position,
        worldName: 'Bossroom.tmx',
        worth: worth,
      );
      game.world1.add(loot);
      game.world1.items.add(loot);
      game.world1.remove(this);
    }
  }
}
