import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/lightning_ball.dart';
import 'package:survivor_test/components/lightning_chain.dart';
import 'package:survivor_test/components/melee.dart';
import 'package:survivor_test/components/mine.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/level.dart';
import 'package:survivor_test/survivor_test.dart';

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

  int stateChooser = 0;
  int attackCounter = 0;
  late double health;
  double attackCooldown = 1;
  late double hitboxRadius;
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

  bool actionCompleted = false;
  bool isDeciding = false;
  bool introStarted = false;
  bool introFinished = false;
  bool isAttacking = false;
  bool hasHitWall = false;

  @override
  FutureOr<void> onLoad() async {
    debugMode = true;
    priority = 1;
    sprite = await Sprite.load('Boss.png');
    hitboxRadius = 108;
    add(
      CircleHitbox(
        radius: hitboxRadius,
        position: size / 2,
        anchor: Anchor.center,
        collisionType: CollisionType.active,
      ),
    );
    health = 200;
    for (Vector2 vector in eightDirectionsRotated) {
      vector.rotate(0.4124);
    }
    spawnPosition = position.clone();
    player = game.player;
    return super.onLoad();
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
      game.gotHitSoundEnemy.start();
      add(
        OpacityEffect.fadeOut(
          EffectController(alternate: true, duration: 0.1, repeatCount: 5),
        ),
      );
    }
    if (other is Mine && other.isExploding) {
      health -= other.damage;

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
    super.onCollision(intersectionPoints, other);
  }

  void _handleHealth() {
    print(health);
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

  void _decideState() async {
    switch (bossState) {
      case BossState.Idle:
        if (!isDeciding) {
          isDeciding = true;
          Future.delayed(Duration(seconds: 1), () {
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
          bossState = BossState.Return;
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
      FlameAudio.play('Wave Attack 1.wav');
      Future.delayed(Duration(seconds: 3), () {
        _finishIntro();
      });
    }
  }

  void _shootAtPlayer() {
    _launchProjectile(lookDirection);
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
        break;
      default:
    }
    print(stateChooser);
    isDeciding = false;
  }

  void _finishIntro() {
    FlameAudio.bgm.play('the_return_of_the_8_bit_era.mp3');
    introFinished = true;
  }

  void _launchProjectile(Vector2 direction, {bool soundON = true}) {
    game.world1.add(
      Projectile(
        position: position,
        moveDirection: direction,
        shooter: Shooter.Enemy,
      ),
    );
    if (soundON) {
      game.shootSoundEnemy.start();
    }
  }

  void _spinAttack() {
    if (multiPurposeTicker <= 0 && spinAttacks.length < 40) {
      multiPurposeTicker = 0.2;
      if (attackCounter > 0) {
        lookDirection.rotate(0.3);
      }
      spinAttacks.add(lookDirection.clone());
      _launchProjectile(spinAttacks[attackCounter]);
      attackCounter += 1;
    }
    if (spinAttacks.length >= 40) {
      attackCounter = 0;
      spinAttacks = [];
      actionCompleted = true;
    }
  }

  void _multiDirectionShot() {
    if (multiPurposeTicker <= 0 && attackCounter < 6) {
      attackCounter += 1;
      multiPurposeTicker = 0.7;
      if ((attackCounter % 2) == 0) {
        multiDirectionAttacks = eightDirectionsRotated;
      } else {
        multiDirectionAttacks = allEightDirections;
      }
      game.shootSoundEnemy.start();
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
      chargeUpPosition = position - lookDirection * 100;
      // FlameAudio.play('Wave Attack 1.wav');
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
    }
    if (!hasHitWall) {
      velocity = chargeTargetPosition * moveSpeed * 5;
      position += velocity * dt;
      for (final block in player.collisionBlocks) {
        if (checkCollision(this, block)) {
          hasHitWall = true;
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
}
