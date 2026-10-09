import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:survivor_test/actors/basic_enemy.dart';
import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/lightning_ball.dart';
import 'package:survivor_test/components/lightning_chain.dart';
import 'package:survivor_test/components/lob.dart';
import 'package:survivor_test/components/melee.dart';
import 'package:survivor_test/components/mine.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/level.dart';
import 'package:survivor_test/survivor_test.dart';

// The values that change with the boss's level (see BossEnemy.levels)
class BossLevelStats {
  final double health;
  // Seconds the boss waits before choosing its next attack
  final double pauseBetweenAttacks;
  const BossLevelStats({
    required this.health,
    required this.pauseBetweenAttacks,
  });
}

enum BossState {
  Idle,
  SingleShot,
  ChargeUp,
  ChargeAt,
  Return,
  MultiDirectionShot,
  SpinAttack,
}

class BossEnemy extends SpriteComponent
    with HasGameReference<SurvivorTest>, CollisionCallbacks {
  BossEnemy({required position})
    : super(position: position, size: Vector2.all(256), anchor: Anchor.center);

  // ---- Hitbox sizes (radius in pixels, the boss image is 256 x 256) ----
  // Hurtbox: the area the player's attacks can hit. Reaches the arm tips.
  static const double hurtboxRadius = 108;
  // Contact zone: the area that damages the player on touch.
  // Covers the pumpkin's body (about 65 pixels), but not the arms.
  static const double contactRadius = 55;

  // ---- Boss levels: the boss gets harder with every fight in a run ----
  // Fight 1 is level 1; after the last entry it stays at the maximum level.
  static const List<BossLevelStats> levels = [
    BossLevelStats(health: 200, pauseBetweenAttacks: 1.0), // level 1
    BossLevelStats(health: 300, pauseBetweenAttacks: 0.9), // level 2
    BossLevelStats(health: 400, pauseBetweenAttacks: 0.8), // level 3
    BossLevelStats(health: 500, pauseBetweenAttacks: 0.7), // level 4
  ];
  // From which level on the boss uses each upgrade
  static const int fanShotFromLevel = 2; // single shot becomes a fan of 3
  static const int seedThrowFromLevel = 2; // sometimes throws a carrot seed
  static const int chargedCarrotsFromLevel = 3; // seed carrots can be charged
  static const int twoArmedSpinFromLevel = 3; // spin attack shoots both ways
  static const int doubleChargeFromLevel = 4; // charges twice in a row
  // Seeds: 1 in [seedChance] single shots becomes a seed, at most
  // [maxSeedCarrots] seed carrots at once, 1 in [chargedCarrotChance] charged
  static const int seedChance = 4;
  static const int maxSeedCarrots = 3;
  static const int chargedCarrotChance = 3;

  late final int bossLevel;
  BossLevelStats get stats => levels[bossLevel - 1];

  int stateChooser = 0;
  int attackCounter = 0;
  late double health;
  double attackCooldown = 1;
  double moveSpeed = 100;
  double multiPurposeTicker = 0;
  BossState bossState = BossState.Idle;

  var random = Random();

  late final Player player;
  late final Level level;
  Vector2 spawnPosition = Vector2.zero();
  Vector2 lookDirection = Vector2.zero();
  Vector2 spinAttackDirection = Vector2.zero();
  Vector2 chargeUpPosition = Vector2.zero();
  Vector2 chargeTargetPosition = Vector2.zero();
  Vector2 velocity = Vector2.zero();

  List<Vector2> spinAttacks = [];
  List<Vector2> multiDirectionAttacks = [];
  List<Mine> alreadyHit = [];
  List<Vector2> allEightDirections = [
    Vector2(0, -1),
    Vector2(1, -1),
    Vector2(1, 0),
    Vector2.all(1),
    Vector2(0, 1),
    Vector2(-1, 1),
    Vector2(-1, 0),
    Vector2.all(-1),
  ];
  List<Vector2> eightDirectionsRotated = [
    Vector2(0, -1),
    Vector2(1, -1),
    Vector2(1, 0),
    Vector2.all(1),
    Vector2(0, 1),
    Vector2(-1, 1),
    Vector2(-1, 0),
    Vector2.all(-1),
  ];

  // Carrots grown from thrown seeds, and seeds still in the air
  final List<BasicEnemy> _seedCarrots = [];
  final List<SpriteComponent> _flyingSeeds = [];
  int get _seedCarrotCount {
    _seedCarrots.removeWhere((carrot) => carrot.isRemoved);
    return _seedCarrots.length + _flyingSeeds.length;
  }

  // Charges left in the current charge attack (2 for a double charge)
  int _chargesLeft = 0;
  bool get _isFollowUpCharge =>
      bossLevel >= doubleChargeFromLevel && _chargesLeft == 1;
  double _chargeTime = 0;

  bool actionCompleted = false;
  bool isDeciding = false;
  bool introStarted = false;
  bool introFinished = false;
  bool isAttacking = false;
  bool hasHitWall = false;

  late var bgm;

  @override
  FutureOr<void> onLoad() async {
    //debugMode = true;
    priority = 1;
    _loadAudio();
    sprite = await Sprite.load('Boss.png');
    add(
      CircleHitbox(
        radius: hurtboxRadius,
        position: size / 2,
        anchor: Anchor.center,
        collisionType: CollisionType.active,
      ),
    );
    add(BossContactZone(radius: contactRadius, position: size / 2));
    bossLevel = SurvivorTest.debugBossLevel > 0
        ? min(SurvivorTest.debugBossLevel, levels.length)
        : min(game.bossesDefeated + 1, levels.length);
    health = stats.health;
    for (Vector2 vector in eightDirectionsRotated) {
      vector.rotate(0.4124);
    }
    spawnPosition = position.clone();
    player = game.player;
    return super.onLoad();
  }

  void _loadAudio() async {
    game.bossBGM = await SoLoud.instance.loadAsset(
      'assets/audio/the_return_of_the_8_bit_era.mp3',
    );
    game.introRoarSound = await SoLoud.instance.loadAsset(
      'assets/audio/Wave Attack 1.wav',
      mode: LoadMode.memory,
    );
    game.victorySound = await SoLoud.instance.loadAsset(
      'assets/audio/VictorySound.mp3',
      mode: LoadMode.memory,
    );
  }

  @override
  void update(double dt) {
    angle = -atan2(lookDirection.x, lookDirection.y);
    attackCooldown -= dt;
    _executeIntro();
    if (introFinished) {
      multiPurposeTicker -= dt;

      _handleHealth();
      _decideState();
      _executeAction(dt);
    } else {
      health = stats.health;
    }
    super.update(dt);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Projectile && other.shooter == Shooter.Player) {
      health -= other.damage;
      other.removeFromParent();
      SoLoud.instance.play(game.gotHitSoundEnemy);
      add(
        OpacityEffect.fadeOut(
          EffectController(alternate: true, duration: 0.1, repeatCount: 5),
        ),
      );
    }

    if (other is Melee) {
      health -= other.damage;
      add(
        OpacityEffect.fadeOut(
          EffectController(alternate: true, duration: 0.1, repeatCount: 5),
        ),
      );
    }
    if (other is LightningBall) {
      health -= other.damage;
      add(
        OpacityEffect.fadeOut(
          EffectController(alternate: true, duration: 0.1, repeatCount: 5),
        ),
      );
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is LightningChain) {
      health -= other.damage;
      add(
        OpacityEffect.fadeOut(
          EffectController(alternate: true, duration: 0.1, repeatCount: 5),
        ),
      );
    }
    if (other is Mine && other.isExploding && !alreadyHit.contains(other)) {
      health -= other.damage;
      alreadyHit.add(other);
      add(
        OpacityEffect.fadeOut(
          EffectController(alternate: true, duration: 0.1, repeatCount: 5),
        ),
      );
    }
    super.onCollision(intersectionPoints, other);
  }

  void _decideState() async {
    switch (bossState) {
      case BossState.Idle:
        if (!isDeciding) {
          isDeciding = true;
          final pause = (stats.pauseBetweenAttacks * 1000).round();
          Future.delayed(Duration(milliseconds: pause), () {
            _randomlyChooseNextState();
          });
        }
        break;
      case BossState.ChargeUp:
        if (actionCompleted) {
          bossState = BossState.ChargeAt;
          isAttacking = false;
        }
        break;
      case BossState.ChargeAt:
        if (actionCompleted) {
          _chargesLeft -= 1;
          // With a double charge it winds up again instead of returning
          bossState = _chargesLeft > 0 ? BossState.ChargeUp : BossState.Return;
          isAttacking = false;
        }
      default:
        if (actionCompleted) {
          bossState = BossState.Idle;
          isAttacking = false;
        }
    }
    actionCompleted = false;
  }

  void _executeAction(double dt) async {
    switch (bossState) {
      case BossState.Idle:
        lookDirection = determineDirectionOfPlayer(player, this);
        break;
      case BossState.SingleShot:
        _shootAtPlayer();
        break;
      case BossState.ChargeUp:
        _chargeUp(dt);
        //charge at player
        // notify when done
        break;
      case BossState.ChargeAt:
        _chargeAtPlayer(dt);
      case BossState.Return:
        _returnToSpawn(dt);
        //return to middle of arena
        //notify when middle reached
        break;
      case BossState.MultiDirectionShot:
        _multiDirectionShot();
        break;
      case BossState.SpinAttack:
        _spinAttack();
    }
  }

  void _executeIntro() async {
    if (introStarted == false) {
      introStarted = true;

      Future.delayed(Duration(seconds: 5), () {
        _playIntro();
      });
    }
  }

  void _shootAtPlayer() {
    if (bossLevel >= seedThrowFromLevel &&
        _seedCarrotCount < maxSeedCarrots &&
        random.nextInt(seedChance) == 0) {
      _throwSeed();
    } else {
      _launchProjectile(lookDirection);
      if (bossLevel >= fanShotFromLevel) {
        _launchProjectile(lookDirection.clone()..rotate(0.3), soundON: false);
        _launchProjectile(lookDirection.clone()..rotate(-0.3), soundON: false);
      }
    }
    actionCompleted = true;
  }

  void _randomlyChooseNextState() {
    stateChooser = random.nextInt(10);
    switch (stateChooser) {
      case 0:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
        bossState = BossState.SingleShot;
        break;
      case 1:
        bossState = BossState.SpinAttack;
        break;
      case 2:
        bossState = BossState.MultiDirectionShot;
        break;
      case 3:
        bossState = BossState.ChargeUp;
        _chargesLeft = bossLevel >= doubleChargeFromLevel ? 2 : 1;
        break;
      default:
    }
    isDeciding = false;
  }

  // Future.delayed keeps counting even when the game is paused or thrown away,
  // so check that the game is still running before playing any sound.
  bool get _gameStopped => !isMounted || game.isGameOver;

  void _playIntro() async {
    if (_gameStopped) return;
    SoLoud.instance.play(game.introRoarSound);
    Future.delayed(Duration(seconds: 5), () async {
      _finishIntro();
    });
  }

  void _launchProjectile(Vector2 direction, {bool soundON = true}) async {
    game.world1.add(
      Projectile(
        position: position,
        moveDirection: direction,
        shooter: Shooter.Enemy,
      ),
    );
    if (soundON) {
      await SoLoud.instance.play(game.shootSoundEnemy);
    }
  }

  // Throws a seed to where the player is standing; it grows into a carrot
  void _throwSeed() {
    final landingSpot = player.position.clone();
    final seed = SpriteComponent.fromImage(
      // PLACEHOLDER art: the apple seed until there's a carrot seed image
      game.images.fromCache(itemImagePath(ItemType.AppleSeed)),
      position: landingSpot,
      size: Vector2.all(32),
      anchor: Anchor.center,
    );
    seed.add(
      Lob(
        from: absoluteCenter,
        onLanded: () {
          _flyingSeeds.remove(seed);
          seed.removeFromParent();
          _growCarrot(landingSpot);
        },
      ),
    );
    _flyingSeeds.add(seed);
    game.world1.add(seed);
    SoLoud.instance.play(game.shootSoundEnemy);
  }

  void _growCarrot(Vector2 spot) {
    final charged =
        bossLevel >= chargedCarrotsFromLevel &&
        random.nextInt(chargedCarrotChance) == 0;
    final carrot = BasicEnemy(
      position: spot,
      enemyType: EnemyType.Medium,
      // Stands still for a moment after growing, then chases the player
      initialMoveDirection: Vector2.zero(),
      startsCharged: charged,
    );
    _seedCarrots.add(carrot);
    game.world1.add(carrot);
    game.enemyCount += 1;
  }

  // When the boss dies, its carrots and seeds still in the air go with it
  void _removeSeedCarrots() {
    for (final carrot in _seedCarrots) {
      if (!carrot.isRemoved) {
        carrot.removeFromParent();
        game.enemyCount -= 1;
      }
    }
    _seedCarrots.clear();
    for (final seed in _flyingSeeds) {
      seed.removeFromParent();
    }
    _flyingSeeds.clear();
  }

  void _spinAttack() {
    if (multiPurposeTicker <= 0 && spinAttacks.length < 40) {
      multiPurposeTicker = 0.2;
      if (attackCounter > 0) {
        lookDirection.rotate(0.3);
      }
      spinAttacks.add(lookDirection.clone());
      _launchProjectile(spinAttacks[attackCounter]);
      if (bossLevel >= twoArmedSpinFromLevel) {
        // Second arm: shoots in the opposite direction at the same time
        _launchProjectile(-spinAttacks[attackCounter], soundON: false);
      }
      attackCounter += 1;
    }
    if (spinAttacks.length >= 40) {
      attackCounter = 0;
      spinAttacks = [];
      actionCompleted = true;
    }
  }

  void _multiDirectionShot() async {
    if (multiPurposeTicker <= 0 && attackCounter < 6) {
      attackCounter += 1;
      multiPurposeTicker = 0.7;
      // The volley stays the same at every level (16 directions at once
      // was too hard to dodge)
      if ((attackCounter % 2) == 0) {
        multiDirectionAttacks = eightDirectionsRotated;
      } else {
        multiDirectionAttacks = allEightDirections;
      }
      await SoLoud.instance.play(game.shootSoundEnemy);
      for (final vector in multiDirectionAttacks) {
        _launchProjectile(vector, soundON: false);
      }
    }
    if (attackCounter >= 6) {
      attackCounter = 0;
      actionCompleted = true;
    }
  }

  void _chargeUp(double dt) {
    if (!isAttacking) {
      lookDirection = determineDirectionOfPlayer(player, this);
      if (_isFollowUpCharge) {
        // Right after hitting a wall: step away from the wall towards the
        // player instead of backing up into the wall
        chargeUpPosition = position + lookDirection * 60;
      } else {
        chargeUpPosition = position - lookDirection * 100;
      }
      isAttacking = true;
    }
    if ((position - chargeUpPosition).length > 2) {
      velocity = determineDirectionOfCorner(chargeUpPosition, this) * moveSpeed;
      position += velocity * dt;
    } else {
      actionCompleted = true;
    }
  }

  void _chargeAtPlayer(double dt) {
    if (!isAttacking) {
      chargeTargetPosition = lookDirection.clone();
      isAttacking = true;
      hasHitWall = false;
      _chargeTime = 0;
    }
    if (!hasHitWall) {
      velocity = chargeTargetPosition * moveSpeed * 5;
      position += velocity * dt;
      _chargeTime += dt;
      // Walls only count after a moment, so a follow-up charge that starts
      // close to a wall doesn't stop immediately
      if (_chargeTime > 0.2) {
        for (final block in player.collisionBlocks) {
          if (checkCollision(this, block)) {
            hasHitWall = true;
          }
        }
      }
    } else {
      actionCompleted = true;
    }
  }

  void _returnToSpawn(double dt) {
    if ((position - spawnPosition).length > 2) {
      velocity = determineDirectionOfCorner(spawnPosition, this) * moveSpeed;
      position += velocity * dt;
    } else {
      actionCompleted = true;
    }
  }

  void _handleHealth() {
    if (health <= 0 && introFinished) {
      SoLoud.instance.stop(bgm);
      SoLoud.instance.play(game.victorySound);
      game.enemyCount -= 1;
      game.bossesDefeated += 1;
      _removeSeedCarrots();
      Item loot = Item(position: position, type: ItemType.Strawberry);

      game.world1.add(loot);
      game.world1.items.add(loot);
      game.world1.remove(this);
    }
  }

  void _finishIntro() async {
    if (_gameStopped) return;
    bgm = await SoLoud.instance.play(game.bossBGM, looping: true);
    introFinished = true;
  }
}

// The area around the pumpkin's body that damages the player on touch.
// It's its own component (instead of a second hitbox on the boss) so the
// player can tell it apart from the boss's bigger hurtbox.
// As a child of the boss, it moves and turns with the boss automatically.
class BossContactZone extends PositionComponent with ParentIsA<BossEnemy> {
  BossContactZone({required double radius, required super.position})
    : super(size: Vector2.all(radius * 2), anchor: Anchor.center);

  BossEnemy get boss => parent;

  @override
  FutureOr<void> onLoad() {
    // Without a radius, the circle fills the whole component
    add(CircleHitbox(collisionType: CollisionType.passive));
    return super.onLoad();
  }
}
