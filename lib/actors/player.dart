import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';

import 'package:survivor_test/actors/basic_enemy.dart';
import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/components/cookie.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/survivor_test.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest>, TapCallbacks, CollisionCallbacks {
  Player({position})
    : super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  //int invincibilityDelay = 1;
  int healthRegenerationDelay = 3;
  double healthRegeneration = 50;
  double health = 400;

  double moveSpeed = 100;
  double playerSpeed = 0;

  double dashBoostMultiplier = 3;
  double stamina = 100;
  double staminaDrain = 30;
  double staminaRecovery = 20;

  double attackCooldown = 2;

  int money = 0;

  Vector2 movementDirection = Vector2.zero();
  Vector2 velocity = Vector2.zero();

  List<CollisionBlock> collisionBlocks = [];
  //List<BasicEnemy> basicEnemies = [];
  List<Cookie> cookies = [];

  bool isDashing = false;
  bool canDash = true;
  bool gotHit = false;
  bool isInjured = false;
  bool isAttacking = false;

  @override
  void onLoad() {
    priority = 1;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('monster.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(64, 60),
        stepTime: 0.12,
      ),
    );
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    if (game.startGame) {
      _updatePlayerMovement(dt);
    }
    _handleHorizontalCollisions(dt);
    _handleVerticalCollisons(dt);
    _handleCookieCollision(dt);
    _handleHealthRegeneration(dt);
    _handleAttacks(dt);
    super.update(dt);
  }

  void _updatePlayerMovement(double dt) {
    if (stamina <= 0) {
      canDash = false;
    }
    if (stamina >= 50) {
      canDash = true;
    }
    if (isDashing && canDash) {
      playerSpeed = moveSpeed * dashBoostMultiplier;
      stamina -= staminaDrain * dt;
    } else {
      playerSpeed = moveSpeed;
      stamina += staminaRecovery * dt;
    }
    velocity = movementDirection * playerSpeed;
    position += velocity * dt;
    stamina = stamina.clamp(0, 100);
  }

  void _handleHorizontalCollisions(double dt) {
    for (final block in collisionBlocks) {
      if (checkCollision(this, block) &&
          isCollisionHorizontal(this, block, dt)) {
        if (velocity.x > 0) {
          velocity.x = 0;
          position.x = block.x - this.width / 2;
          break;
        }
        if (velocity.x < 0) {
          velocity.x = 0;
          position.x = block.x + block.width + this.width / 2;
          break;
        }
      }
    }
  }

  void _handleVerticalCollisons(double dt) {
    for (final block in collisionBlocks) {
      if (checkCollision(this, block) && isCollisionVertical(this, block, dt)) {
        if (velocity.y > 0) {
          velocity.y = 0;
          position.y = block.y - this.height / 2;
          break;
        }
        if (velocity.y < 0) {
          velocity.y = 0;
          position.y = block.y + block.height + this.height / 2;
        }
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is BasicEnemy && !gotHit) {
      health -= 100;
      gotHit = true;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  Future<void> _handleHealthRegeneration(double dt) async {
    if (gotHit) {
      add(
        OpacityEffect.fadeOut(
            EffectController(alternate: true, duration: 0.1, repeatCount: 5),
          )
          ..onComplete = () {
            gotHit = false;
          },
      );
      Future.delayed(
        Duration(seconds: healthRegenerationDelay),
        () => isInjured = true,
      );
    } else if (isInjured && health < 300) {
      health += healthRegeneration * dt;
      health.clamp(-50, 300);
    } else if (health >= 300) {
      isInjured = false;
    }
  }

  void _handleAttacks(double dt) {
    attackCooldown -= dt;
    if (isAttacking && attackCooldown <= 0) {
      attackCooldown = 2;
      game.world1.add(
        Projectile(position: position, moveDirection: movementDirection),
      );
    }
  }

  void _handleCookieCollision(double dt) {
    cookies = game.world1.cookies;
    if (cookies.length != 0) {
      for (Cookie cookie in cookies) {
        if (checkCollision(this, cookie)) {
          cookie.removeFromParent();
          money += cookie.worth;
        }
        ;
      }
    }
  }
}
