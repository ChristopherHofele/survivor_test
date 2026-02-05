import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/level.dart';
import 'package:survivor_test/survivor_test.dart';

enum BossState {
  Idle,
  SingleShot,
  Charge,
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
  late double attackCooldown;
  late double hitboxRadius;
  double multiPurposeTicker = 0;
  BossState bossState = BossState.Idle;

  var random = Random();

  late final Player player;
  late final Level level;
  Vector2 lookDirection = Vector2.zero();
  Vector2 spinAttackDirection = Vector2.zero();

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
    for (Vector2 vector in eightDirectionsRotated) {
      vector.rotate(0.4124);
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _executeIntro();
    if (introFinished) {
      multiPurposeTicker -= dt;

      _handleHealth();
      _decideState();
      _executeAction();
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

  void _decideState() async {
    if (bossState == BossState.Idle && !isDeciding) {
      isDeciding = true;
      Future.delayed(Duration(seconds: 1), () {
        _randomlyChooseNextState();
      });
    } else if (actionCompleted) {
      bossState = BossState.Idle;
      isAttacking = false;
    }
    actionCompleted = false;
  }

  void _executeAction() async {
    switch (bossState) {
      case BossState.Idle:
        lookDirection = determineDirectionOfPlayer(game.player, this);
        break;
      case BossState.SingleShot:
        _shootAtPlayer();
        break;
      case BossState.Charge:
        //charge at player
        // notify when done
        break;
      case BossState.Return:
        //return to middle of arena
        //notify when middle reached
        break;
      case BossState.MultiDirectionShot:
        _multiDirectionShot();
        //shoot in 8 directions then change by 22.5 degrees shoot again,
        //change angle back and shoot again
        //notify when done
        break;
      case BossState.SpinAttack:
        // shoot at certain intervals while spinning
        // do 3 spins then notify when done
        _spinAttack();
    }
  }

  void _executeIntro() async {
    if (introStarted == false) {
      print('Intro started');
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
    stateChooser = random.nextInt(4);
    switch (stateChooser) {
      case 0:
        bossState = BossState.SingleShot;
        break;
      case 1:
        bossState = BossState.SpinAttack;
        break;
      case 2:
        bossState = BossState.MultiDirectionShot;
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
}
