import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';

import 'package:survivor_test/actors/basic_enemy.dart';
import 'package:survivor_test/actors/boss_enemy.dart';
import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/lightning_ball.dart';
import 'package:survivor_test/components/lightning_chain.dart';
import 'package:survivor_test/components/melee.dart';
import 'package:survivor_test/components/mine.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/overlays/key_display.dart';
import 'package:survivor_test/survivor_test.dart';

enum CharacterChoice { FireGuy, MineFellow, MeleeLad, DashMan }

enum CharacterState { LevelOne, LevelTwo, LevelThree }

class Player extends SpriteAnimationGroupComponent
    with
        HasGameReference<SurvivorTest>,
        TapCallbacks,
        CollisionCallbacks,
        HasVisibility {
  CharacterChoice characterChoice;
  Player({position, required this.characterChoice})
    : super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  late final SpriteAnimation levelOneAnimation;
  late final SpriteAnimation levelTwoAnimation;
  late final SpriteAnimation levelThreeAnimation;

  int money = 0;
  //int invincibilityDelay = 1;
  int healthRegenerationDelay = 3;
  int projectileMaximumHits = 2;

  double healthRegeneration = 50;
  double health = 300;
  double maxHealth = 300;

  double moveSpeed = 100;
  double playerSpeed = 0;

  double dashBoostMultiplier = 3;
  double stamina = 100;
  double staminaDrain = 30;
  double staminaRecovery = 20;

  double attackCooldown = 1.6;
  double maxAttackCooldown = 1.6;

  double buyCooldown = 0;

  Vector2 movementDirection = Vector2.zero();
  Vector2 shootDirection = Vector2(0, 1);
  Vector2 velocity = Vector2.zero();

  List<CollisionBlock> collisionBlocks = [];
  List<LightningBall> lightningBalls = [];
  //List<BasicEnemy> basicEnemies = [];

  bool isDashing = false;
  bool canDash = true;
  bool gotHit = false;
  bool isInjured = false;
  bool isAttacking = false;
  bool allowedTeleportation = false;
  bool hasFruit = false;
  bool hasKey = false;
  bool inside = false;
  bool zapFinished = false;

  KeyDisplay keyDisplay = KeyDisplay();

  @override
  void onLoad() {
    //debugMode = true;
    isVisible = true;
    priority = 1;
    _loadAllAnimations();
    _initializeCharacterStats();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    if (game.startGame) {
      _updatePlayerMovement(dt);
      _saveShootDirection();
      _handleBlockCollisions(dt);
      _handleItemCollision(dt);
      _handleHealthRegeneration(dt);
      _handleAttacks(dt);
      _updateInside();
    }
    super.update(dt);
  }

  void _loadAllAnimations() {
    switch (characterChoice) {
      case CharacterChoice.FireGuy:
        levelOneAnimation = _spriteAnimation('LevelOne');
        levelTwoAnimation = _spriteAnimation('LevelTwo');
        levelThreeAnimation = _spriteAnimation('LevelThree');

        break;
      case CharacterChoice.MineFellow:
        levelOneAnimation = _spriteAnimation('MineFellowOne');
        levelTwoAnimation = _spriteAnimation('MineFellowTwo');
        levelThreeAnimation = _spriteAnimation('MineFellowThree');
        break;
      case CharacterChoice.MeleeLad:
        levelOneAnimation = _spriteAnimation('MeleeLadOne');
        levelTwoAnimation = _spriteAnimation('MeleeLadTwo');
        levelThreeAnimation = _spriteAnimation('MeleeLadThree');
        break;
      case CharacterChoice.DashMan:
        levelOneAnimation = _spriteAnimation('DashManOne');
        levelTwoAnimation = _spriteAnimation('DashManTwo');
        levelThreeAnimation = _spriteAnimation('DashManThree');
        break;
    }

    animations = {
      CharacterState.LevelOne: levelOneAnimation,
      CharacterState.LevelTwo: levelTwoAnimation,
      CharacterState.LevelThree: levelThreeAnimation,
    };

    current = CharacterState.LevelThree;
  }

  SpriteAnimation _spriteAnimation(String state) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('$state.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.12,
        textureSize: Vector2(64, 64),
      ),
    );
  }

  void _updatePlayerMovement(double dt) {
    if (isVisible) {
      if (stamina <= 0) {
        canDash = false;
      }
      if (stamina >= 50) {
        canDash = true;
      }
    }
    if (isDashing && canDash) {
      isVisible
          ? playerSpeed = moveSpeed * dashBoostMultiplier
          : playerSpeed = moveSpeed * dashBoostMultiplier * 3;
      stamina -= staminaDrain * dt;
    } else {
      playerSpeed = moveSpeed;
      stamina += staminaRecovery * dt;
    }
    if (isVisible) {
      velocity = movementDirection * playerSpeed;
    } else {
      velocity = shootDirection * playerSpeed;
    }
    position += velocity * dt;
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
    stamina = stamina.clamp(0, 100);
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
                if (hasFruit) {
                  allowedTeleportation = true;
                  hasFruit = false;
                }
                break;
              case 'Health.tmx':
              case 'Stamina.tmx':
              case 'Damage.tmx':
                if (money >= block.entryCost) {
                  allowedTeleportation = true;
                  money -= block.entryCost;
                  if (game.doorsOpened < 3) {
                    game.doorsOpened += 1;
                  }
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
      if (isVisible) {
        health -= 100;
        gotHit = true;
        game.gotHitSoundPlayer.start();
      }
      other.removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (isVisible) {
      if (other is BasicEnemy && other.attackCooldown <= 0) {
        health -= 100;
        gotHit = true;
        other.attackCooldown = 1;
        game.gotHitSoundPlayer.start();
      }
      if (other is BossEnemy && other.attackCooldown <= 0) {
        health -= 100;
        gotHit = true;
        other.attackCooldown = 1;
        game.gotHitSoundPlayer.start();
      }
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
    switch (characterChoice) {
      case CharacterChoice.FireGuy:
        _fireGuyAttacks();
        break;
      case CharacterChoice.MineFellow:
        _mineFellowAttacks();
        break;
      case CharacterChoice.MeleeLad:
        _meleeLadAttacks();
        break;
      case CharacterChoice.DashMan:
        _dashManAttacks(dt);
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
                hasFruit = true;
                game.eatFruitSound.start();
                break;
              case 'Bananas':
                staminaDrain -= 10;
                hasFruit = true;
                game.eatFruitSound.start();
                break;
              case 'Cherries':
                maxAttackCooldown = maxAttackCooldown * 0.5;
                projectileMaximumHits += 1;
                hasFruit = true;
                game.eatFruitSound.start();
                break;
              case 'Strawberry':
                _packAPunch();
                hasFruit = true;
                game.eatFruitSound.start();
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
      case CharacterState.LevelOne:
        current = CharacterState.LevelTwo;

        break;
      case CharacterState.LevelTwo:
        current = CharacterState.LevelThree;
      default:
    }
    resetMaxAttackCooldown();
  }

  void _updateInside() {
    if (!game.world1.pressurePlates.isEmpty) {
      for (final plate in game.world1.pressurePlates) {
        if (checkCollision(this, plate)) {
          if (plate.inside) {
            inside = true;
          } else {
            inside = false;
          }
        }
      }
    }
  }

  void resetMaxAttackCooldown() {
    maxAttackCooldown = 1.6;
  }

  void _fireGuyAttacks() {
    if (isAttacking && attackCooldown <= 0) {
      attackCooldown = maxAttackCooldown;
      game.world1.add(
        Projectile(position: position, moveDirection: shootDirection),
      );
      game.shootSoundPlayer.start();

      switch (current) {
        case CharacterState.LevelTwo:
          Vector2 leftShot = movementDirection.clone();
          Vector2 rightShot = movementDirection.clone();
          leftShot.rotate(0.3);
          rightShot.rotate(-0.3);
          game.world1.add(
            Projectile(position: position, moveDirection: leftShot),
          );
          game.world1.add(
            Projectile(position: position, moveDirection: rightShot),
          );
        case CharacterState.LevelThree:
          Vector2 leftShot = movementDirection.clone();
          Vector2 rightShot = movementDirection.clone();
          leftShot.rotate(0.3);
          rightShot.rotate(-0.3);
          game.world1.add(
            Projectile(position: position, moveDirection: leftShot),
          );
          game.world1.add(
            Projectile(position: position, moveDirection: rightShot),
          );
          game.world1.add(
            Projectile(position: position, moveDirection: -movementDirection),
          );
        default:
      }
    }
  }

  void _mineFellowAttacks() {
    if (isAttacking && attackCooldown <= 0) {
      attackCooldown = maxAttackCooldown;

      switch (current) {
        case CharacterState.LevelOne:
          game.world1.add(
            Mine(
              position: position,
              moveDirection: Vector2.zero(),
              soundON: true,
            ),
          );
        case CharacterState.LevelTwo:
          game.world1.add(
            Mine(
              position: position,
              moveDirection: Vector2.zero(),
              soundON: true,
            ),
          );
          game.world1.add(
            Mine(
              position: position,
              moveDirection: shootDirection,
              soundON: false,
            ),
          );

          break;
        case CharacterState.LevelThree:
          Vector2 leftShot = shootDirection.clone();
          Vector2 rightShot = shootDirection.clone();
          leftShot *= -1;
          rightShot *= -1;
          leftShot.rotate(0.3);
          rightShot.rotate(-0.3);
          game.world1.add(
            Mine(
              position: position,
              moveDirection: shootDirection,
              soundON: true,
            ),
          );
          game.world1.add(
            Mine(position: position, moveDirection: leftShot, soundON: false),
          );
          game.world1.add(
            Mine(position: position, moveDirection: rightShot, soundON: false),
          );
          break;
        default:
      }
    }
  }

  void _saveShootDirection() {
    if (movementDirection != Vector2(0, 0)) {
      shootDirection = movementDirection;
    }
  }

  void _meleeLadAttacks() {
    if (isAttacking && attackCooldown <= 0) {
      attackCooldown = maxAttackCooldown;

      switch (current) {
        case CharacterState.LevelOne:
          game.world1.add(
            Melee(
              position: position + shootDirection * size.x,
              meleeDirection: shootDirection,
              strength: 0,
              soundON: true,
            ),
          );
          break;
        case CharacterState.LevelTwo:
          game.world1.add(
            Melee(
              position: position + shootDirection * size.x,
              meleeDirection: shootDirection,
              strength: 0,
              soundON: true,
            ),
          );
          game.world1.add(
            Melee(
              position: position + shootDirection * size.x,
              meleeDirection: shootDirection,
              strength: 1,
              soundON: false,
            ),
          );
          break;
        case CharacterState.LevelThree:
          game.world1.add(
            Melee(
              position: position + shootDirection * size.x,
              meleeDirection: shootDirection,
              strength: 0,
              soundON: true,
            ),
          );
          game.world1.add(
            Melee(
              position: position + shootDirection * size.x * 1.5,
              meleeDirection: shootDirection,
              strength: 1,
              soundON: false,
            ),
          );
          game.world1.add(
            Melee(
              position: position + shootDirection * size.x * 1.5,
              meleeDirection: shootDirection,
              strength: 2,
              soundON: false,
            ),
          );
          break;
        default:
      }
    }
  }

  void _dashManAttacks(double dt) {
    if (isAttacking && attackCooldown <= 0) {
      if (isVisible) {
        attackCooldown = maxAttackCooldown;
        game.world1.add(LightningBall(position: position, isStationary: false));
        game.electricitySound.start();
      }
      switch (current) {
        case CharacterState.LevelTwo:
          zapFinished = false;
          LightningBall lightningBall = LightningBall(position: position);
          game.world1.add(lightningBall);
          lightningBalls.add(lightningBall);
          //spawn stationary orb
          //remember position and connect with lightning
          break;
        case CharacterState.LevelThree:
          zapFinished = false;
          LightningBall lightningBall = LightningBall(position: position);
          game.world1.add(lightningBall);
          lightningBalls.add(lightningBall);

          break;
        default:
      }
    }
    if (isVisible) {
      switch (current) {
        case CharacterState.LevelTwo:
          if (lightningBalls.length == 2) {
            executeLevelTwoZap();
          }
          break;
        case CharacterState.LevelThree:
          if (lightningBalls.length == 4) {
            executeLevelThreeZap();
          }
        default:
      }
    }
  }

  void executeLevelThreeZap() {
    for (int i = 0; i < 3; i++) {
      game.world1.add(
        LightningChain(
          position: lightningBalls[i].position,
          endPosition: lightningBalls[i + 1].position,
        ),
      );
    }
    game.world1.add(
      LightningChain(
        position: lightningBalls[3].position,
        endPosition: lightningBalls[0].position,
      ),
    );
    game.world1.add(
      LightningChain(
        position: lightningBalls[0].position,
        endPosition: lightningBalls[2].position,
      ),
    );
    game.world1.add(
      LightningChain(
        position: lightningBalls[1].position,
        endPosition: lightningBalls[3].position,
      ),
    );
    game.lightningChainSound.start();
    lightningBalls = [];
  }

  void executeLevelTwoZap() {
    game.world1.add(
      LightningChain(
        position: lightningBalls[0].position,
        endPosition: lightningBalls[1].position,
      ),
    );
    game.lightningChainSound.start();
    lightningBalls = [];
  }

  void _initializeCharacterStats() {
    switch (characterChoice) {
      case CharacterChoice.DashMan:
        attackCooldown = 4;
        maxAttackCooldown = 4;
        break;
      default:
    }
  }
}
