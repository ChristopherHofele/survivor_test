import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

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

enum CharacterChoice { FireGuy, MineFellow, MeleeLad, DashMan, Undecided }

// The character's upgrade level (raised by eating a strawberry)
enum CharacterState { LevelOne, LevelTwo, LevelThree }

// Which animation the player is showing
enum PlayerAnimation { Idle, Walking }

// The sprite sheets for one character. Each sheet has all its frames in a
// single row; the number of frames is worked out from the image width.
class CharacterSprites {
  final String idle;
  final String walking;
  final double frameSize;
  const CharacterSprites({
    required this.idle,
    required this.walking,
    this.frameSize = 64,
  });
}

// All levels use the same art for now. To add a new character, add a line here.
const Map<CharacterChoice, CharacterSprites> characterSprites = {
  CharacterChoice.FireGuy: CharacterSprites(
    idle: 'FireGuy.png',
    walking: 'FireGuy_Walking.png',
  ),
  CharacterChoice.DashMan: CharacterSprites(
    idle: 'DashMan.png',
    walking: 'DashMan_Walking.png',
  ),
  CharacterChoice.MeleeLad: CharacterSprites(
    idle: 'MeleeLad.png',
    walking: 'MeleeLad_Walking.png',
  ),
  CharacterChoice.MineFellow: CharacterSprites(
    idle: 'MineFellow.png',
    // No walking sheet yet, so the idle sheet is used for walking too
    walking: 'MineFellow.png',
  ),
};

class Player extends SpriteAnimationGroupComponent<PlayerAnimation>
    with
        HasGameReference<SurvivorTest>,
        TapCallbacks,
        CollisionCallbacks,
        HasVisibility {
  Player({position, })
    : super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  CharacterChoice characterChoice = CharacterChoice.FireGuy;
  CharacterState level = CharacterState.LevelOne;
  int money = 100;
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

  // The character's starting cooldown, before any cherries
  double baseAttackCooldown = 1.6;
  double attackCooldown = 1.6;
  double maxAttackCooldown = 1.6;

  double buyCooldown = 0;
  double regenerationCooldown = 0;

  Vector2 movementDirection = Vector2.zero();
  Vector2 shootDirection = Vector2(0, 1);
  Vector2 velocity = Vector2.zero();

  List<CollisionBlock> collisionBlocks = [];
  List<LightningBall> lightningBalls = [];
  //List<BasicEnemy> basicEnemies = [];

  bool isDashing = false;
  bool canDash = true;
  bool isAttacking = false;
  bool allowedTeleportation = false;
  bool hasFruit = false;
  bool hasKey = false;
  bool inside = false;
  bool zapFinished = false;

  KeyDisplay keyDisplay = KeyDisplay();

  late AudioSource gotHitSoundPlayer;
  late AudioSource explosionSound;
  late AudioSource fuseSound;
  late AudioSource slashSound;
  late AudioSource electricitySound;
  late AudioSource lightningChainSound;
  late AudioSource shootSound;
  late AudioSource eatFruitSound;

  @override
  void onLoad() async {
    //debugMode = true;
    await getChracterChoice();
    isVisible = true;
    priority = 1;

    _loadSounds();
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
    final sprites = characterSprites[characterChoice]!;
    final frameSize = Vector2.all(sprites.frameSize);
    animations = {
      PlayerAnimation.Idle: spriteSheetAnimation(
        game.images,
        sprites.idle,
        frameSize,
      ),
      PlayerAnimation.Walking: spriteSheetAnimation(
        game.images,
        sprites.walking,
        frameSize,
      ),
    };
    current = PlayerAnimation.Idle;
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
    current = velocity.isZero()
        ? PlayerAnimation.Idle
        : PlayerAnimation.Walking;
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
              game.world1.stopBGM();
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
        _takeHit();
      }
      other.removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (isVisible) {
      if (other is BasicEnemy && other.attackCooldown <= 0) {
        other.attackCooldown = 1;
        _takeHit();
      }
      // Only the boss's contact zone hurts, not its bigger hurtbox
      if (other is BossContactZone && other.boss.attackCooldown <= 0) {
        other.boss.attackCooldown = 1;
        _takeHit();
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  // Everything that happens once when the player gets hit
  void _takeHit() {
    health -= 100;
    // Every hit restarts the wait before health regenerates
    regenerationCooldown = healthRegenerationDelay.toDouble();
    add(
      OpacityEffect.fadeOut(
        EffectController(alternate: true, duration: 0.1, repeatCount: 5),
      ),
    );
    SoLoud.instance.play(gotHitSoundPlayer);
  }

  void _handleHealthRegeneration(double dt) {
    regenerationCooldown -= dt;
    if (regenerationCooldown <= 0 && health < maxHealth) {
      health = (health + healthRegeneration * dt).clamp(0, maxHealth).toDouble();
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
        break;
      default:
    }
  }

  void _handleItemCollision(double dt) async {
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
                hasFruit = true;
                await SoLoud.instance.play(eatFruitSound);
                break;
              case 'Bananas':
                staminaDrain -= 10;
                hasFruit = true;
                await SoLoud.instance.play(eatFruitSound);
                break;
              case 'Cherries':
                maxAttackCooldown = maxAttackCooldown * 0.5;
                projectileMaximumHits += 1;
                hasFruit = true;
                await SoLoud.instance.play(eatFruitSound);
                break;
              case 'Strawberry':
                _packAPunch();
                hasFruit = true;
                await SoLoud.instance.play(eatFruitSound);
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
    switch (level) {
      case CharacterState.LevelOne:
        level = CharacterState.LevelTwo;

        break;
      case CharacterState.LevelTwo:
        level = CharacterState.LevelThree;
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

  // Levelling up removes any cherry speed bonus and goes back to the
  // character's own starting cooldown
  void resetMaxAttackCooldown() {
    maxAttackCooldown = baseAttackCooldown;
  }

  void _fireGuyAttacks() {
    if (isAttacking && attackCooldown <= 0) {
      attackCooldown = maxAttackCooldown;
      game.world1.add(
        Projectile(position: position, moveDirection: shootDirection),
      );

      SoLoud.instance.play(shootSound);

      switch (level) {
        case CharacterState.LevelTwo:
          Vector2 leftShot = shootDirection.clone();
          Vector2 rightShot = shootDirection.clone();
          leftShot.rotate(0.3);
          rightShot.rotate(-0.3);
          game.world1.add(
            Projectile(position: position, moveDirection: leftShot),
          );
          game.world1.add(
            Projectile(position: position, moveDirection: rightShot),
          );
        case CharacterState.LevelThree:
          Vector2 leftShot = shootDirection.clone();
          Vector2 rightShot = shootDirection.clone();
          leftShot.rotate(0.3);
          rightShot.rotate(-0.3);
          game.world1.add(
            Projectile(position: position, moveDirection: leftShot),
          );
          game.world1.add(
            Projectile(position: position, moveDirection: rightShot),
          );
          game.world1.add(
            Projectile(position: position, moveDirection: -shootDirection),
          );
        default:
      }
    }
  }

  void _mineFellowAttacks() {
    if (isAttacking && attackCooldown <= 0) {
      attackCooldown = maxAttackCooldown;

      switch (level) {
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

      switch (level) {
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
      }
    }
  }

  void _dashManAttacks(double dt) async {
    if (isAttacking && attackCooldown <= 0) {
      if (isVisible) {
        attackCooldown = maxAttackCooldown;
        game.world1.add(LightningBall(position: position, isStationary: false));
        await SoLoud.instance.play(electricitySound);
      }
      switch (level) {
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
      switch (level) {
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

  void executeLevelThreeZap() async {
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
    await SoLoud.instance.play(lightningChainSound);
    lightningBalls = [];
  }

  void executeLevelTwoZap() async {
    game.world1.add(
      LightningChain(
        position: lightningBalls[0].position,
        endPosition: lightningBalls[1].position,
      ),
    );
    await SoLoud.instance.play(lightningChainSound);
    lightningBalls = [];
  }

  void _initializeCharacterStats() {
    switch (characterChoice) {
      case CharacterChoice.DashMan:
        baseAttackCooldown = 4;
        break;
      default:
    }
    attackCooldown = baseAttackCooldown;
    maxAttackCooldown = baseAttackCooldown;
  }

  void _loadSounds() async {
    switch (characterChoice) {
      case CharacterChoice.FireGuy:
        shootSound = await SoLoud.instance.loadAsset(
          'assets/audio/Fireball 1.wav',
          mode: LoadMode.memory,
        );
        break;
      case CharacterChoice.MineFellow:
        explosionSound = await SoLoud.instance.loadAsset(
          'assets/audio/Explosion.mp3',
          mode: LoadMode.memory,
        );
        fuseSound = await SoLoud.instance.loadAsset(
          'assets/audio/Fuse.mp3',
          mode: LoadMode.memory,
        );

        break;
      case CharacterChoice.MeleeLad:
        slashSound = await SoLoud.instance.loadAsset(
          'assets/audio/Slash.mp3',
          mode: LoadMode.memory,
        );
        break;
      case CharacterChoice.DashMan:
        electricitySound = await SoLoud.instance.loadAsset(
          'assets/audio/ElectricDash.mp3',
          mode: LoadMode.memory,
        );

        lightningChainSound = await SoLoud.instance.loadAsset(
          'assets/audio/LightningChain.mp3',
          mode: LoadMode.memory,
        );
        break;
      default:
    }

    gotHitSoundPlayer = await SoLoud.instance.loadAsset(
      'assets/audio/Bow Blocked 1.wav',
      mode: LoadMode.memory,
    );
    eatFruitSound = await SoLoud.instance.loadAsset(
      'assets/audio/Apple Crunch.mp3',
      mode: LoadMode.memory,
    );
  }
  
  Future<void> getChracterChoice() async {
    while (game.selectedCharacter == CharacterChoice.Undecided) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    characterChoice = game.selectedCharacter;  
  } 
}
