import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';

import 'package:survivor_test/actors/basic_enemy.dart';
import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/overlays/key_display.dart';
import 'package:survivor_test/survivor_test.dart';

enum PlayerState { LevelOne, LevelTwo, LevelThree }

class Player extends SpriteAnimationGroupComponent
    with HasGameReference<SurvivorTest>, TapCallbacks, CollisionCallbacks {
  Player({position})
    : super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  late final SpriteAnimation levelOneAnimation;
  late final SpriteAnimation levelTwoAnimation;
  late final SpriteAnimation levelThreeAnimation;

  int money = 0;
  //int invincibilityDelay = 1;
  int healthRegenerationDelay = 3;
  int projectileMaximumHits = 3;

  double healthRegeneration = 50;
  double health = 400;
  double maxHealth = 400;

  double moveSpeed = 100;
  double playerSpeed = 0;

  double dashBoostMultiplier = 3;
  double stamina = 100;
  double staminaDrain = 30;
  double staminaRecovery = 20;

  double attackCooldown = 2;
  double maxAttackCooldown = 2;

  double buyCooldown = 0;

  Vector2 movementDirection = Vector2.zero();
  Vector2 velocity = Vector2.zero();

  List<CollisionBlock> collisionBlocks = [];
  //List<BasicEnemy> basicEnemies = [];

  bool isDashing = false;
  bool canDash = true;
  bool gotHit = false;
  bool isInjured = false;
  bool isAttacking = false;
  bool allowedTeleportation = false;
  bool hasKey = false;

  KeyDisplay keyDisplay = KeyDisplay();

  @override
  void onLoad() {
    //debugMode = true;
    priority = 1;
    _loadAllAnimations();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    if (game.startGame) {
      _updatePlayerMovement(dt);
      _handleBlockCollisions(dt);
      _handleItemCollision(dt);
      _handleHealthRegeneration(dt);
      _handleAttacks(dt);
      //print(health.toString() + ', ' + maxHealth.toString());
      //print(collisionBlocks.length);
    }
    super.update(dt);
  }

  void _loadAllAnimations() {
    levelOneAnimation = _spriteAnimation('LevelOne');
    levelTwoAnimation = _spriteAnimation('LevelTwo');
    levelThreeAnimation = _spriteAnimation('LevelThree');

    animations = {
      PlayerState.LevelOne: levelOneAnimation,
      PlayerState.LevelTwo: levelTwoAnimation,
      PlayerState.LevelThree: levelThreeAnimation,
    };

    current = PlayerState.LevelOne;
  }

  SpriteAnimation _spriteAnimation(String state) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('$state.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.12,
        textureSize: Vector2(64, 60),
      ),
    );
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
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
    stamina = stamina.clamp(0, 100);
    //print(position);
  }

  void _handleBlockCollisions(double dt) {
    int collisionCounter = 0;
    buyCooldown -= dt;
    for (final block in collisionBlocks) {
      if (checkCollision(this, block)) {
        switch (block.interactionType) {
          case InteractionType.DamageShop:
          case InteractionType.HealthShop:
          case InteractionType.StaminaShop:
            break;
          case InteractionType.Portal:
            switch (block.destinationName) {
              case 'Level1.tmx':
                allowedTeleportation = true;
                break;
              case 'Health.tmx':
              case 'Stamina.tmx':
              case 'Damage.tmx':
                if (money >= block.entryCost) {
                  allowedTeleportation = true;
                  money -= block.entryCost;
                  game.doorsOpened += 1;
                }
              case 'Bossroom.tmx':
                if (hasKey) {
                  allowedTeleportation = true;
                  hasKey = false;
                  game.camera.viewport.remove(keyDisplay);
                }

              default:
            }
            if (allowedTeleportation) {
              game.world1.removeFromParent();
              game.loadWorld(this, block.destinationName);
              position = block.teleportCoordinates;
              game.enemyCount = 0;
              allowedTeleportation = false;
            }
            break;
          default:
            _handleHorizontalCollisions(dt, block)
                ? collisionCounter += 1
                : collisionCounter;
            _handleVerticalCollisons(dt, block)
                ? collisionCounter += 1
                : collisionCounter;
        }
      }
      if (collisionCounter >= 2) {
        print('two collisions');
        break;
      }
    }
  }

  bool _handleHorizontalCollisions(double dt, block) {
    if (isCollisionHorizontal(this, block, dt)) {
      if (velocity.x > 0) {
        velocity.x = 0;
        position.x = block.x - this.width / 2;
      }
      if (velocity.x < 0) {
        velocity.x = 0;
        position.x = block.x + block.width + this.width / 2;
      }
      return true;
    } else {
      return false;
    }
  }

  bool _handleVerticalCollisons(double dt, block) {
    if (isCollisionVertical(this, block, dt)) {
      if (velocity.y > 0) {
        velocity.y = 0;
        position.y = block.y - this.height / 2;
      }
      if (velocity.y < 0) {
        velocity.y = 0;
        position.y = block.y + block.height + this.height / 2;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Projectile && other.shooter == Shooter.Enemy) {
      health -= 100;
      gotHit = true;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is BasicEnemy && other.attackCooldown <= 0) {
      health -= 100;
      gotHit = true;
      other.attackCooldown = 1;
    }

    super.onCollision(intersectionPoints, other);
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
    } else if (isInjured && health < maxHealth) {
      health += healthRegeneration * dt;
    } else if (health >= maxHealth) {
      isInjured = false;
      health = maxHealth;
    }
  }

  void _handleAttacks(double dt) {
    attackCooldown -= dt;
    if (isAttacking && attackCooldown <= 0) {
      attackCooldown = maxAttackCooldown;
      game.world1.add(
        Projectile(position: position, moveDirection: movementDirection),
      );
    }
  }

  void _handleItemCollision(double dt) {
    if (game.world1.items.length != 0) {
      List<Item> itemsToRemove = [];
      for (final item in game.world1.items) {
        if (checkCollision(this, item)) {
          itemsToRemove.add(item);
          item.removeFromParent();
          money += item.worth;
          if (item.worth != 1) {
            switch (item.spriteName) {
              case 'Apple':
                maxHealth += 100;
                isInjured = true;
                break;
              case 'Bananas':
                staminaDrain -= 8;
                break;
              case 'Cherries':
                maxAttackCooldown = maxAttackCooldown * 0.25;
                projectileMaximumHits += 1;
                break;
              case 'Strawberry':
                _packAPunch();
              case 'Key':
                hasKey = true;
                game.camera.viewport.add(keyDisplay);

              default:
            }
          }
        }
      }
      for (Item item in itemsToRemove) {
        game.world1.items.remove(item);
      }
    }
  }

  void _packAPunch() {
    switch (current) {
      case PlayerState.LevelOne:
        current = PlayerState.LevelTwo;

        break;
      case PlayerState.LevelTwo:
        current = PlayerState.LevelThree;
      default:
    }
  }
}
