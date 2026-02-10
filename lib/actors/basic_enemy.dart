import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/lightning_ball.dart';
import 'package:survivor_test/components/lightning_chain.dart';
import 'package:survivor_test/components/melee.dart';
import 'package:survivor_test/components/mine.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/level.dart';
import 'package:survivor_test/survivor_test.dart';

enum EnemyType { Small, Medium, Big }

class BasicEnemy extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest>, CollisionCallbacks {
  EnemyType enemyType;
  Vector2 initialMoveDirection;
  BasicEnemy({
    required position,
    required this.enemyType,
    required this.initialMoveDirection,
  }) : super(position: position, size: Vector2.all(64), anchor: Anchor.center);

  late double moveSpeed;
  late double health;
  late double attackCooldown;
  late double hitboxRadius;
  double shootCooldown = 5;
  double selfDestruct = 8;
  double followCornerCooldown = 0.3;
  double getOutOfSpawn = 1.5;
  double ignoreCornerCooldown = 0.3;

  var random = Random();

  late final Player player;
  late final Level level;

  late Vector2 textureSize;
  Vector2 movementDirection = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  Vector2 directionOfPlayer = Vector2.zero();
  Vector2 cornerToFollow = Vector2.zero();

  List<CollisionBlock> collisionBlocks = [];
  List<Mine> alreadyHit = [];

  bool followPlayer = true;
  bool ignoreCorner = false;

  late String spriteName;

  @override
  void onLoad() async {
    //debugMode = true;
    _initializeEnemyType();

    player = game.player;
    collisionBlocks = player.collisionBlocks;
    priority = 1;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache(spriteName),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: textureSize,
        stepTime: 0.12,
      ),
    );
    add(
      CircleHitbox(
        radius: hitboxRadius,
        position: size / 2,
        anchor: Anchor.center,
        collisionType: CollisionType.active,
      ),
    );
  }

  void _initializeEnemyType() {
    switch (enemyType) {
      case EnemyType.Small:
        spriteName = 'enemy_small.png';
        textureSize = Vector2.all(32);
        hitboxRadius = 16;
        moveSpeed = 140;
        health = 1;
        attackCooldown = 1;
        getOutOfSpawn = 0.5;

        break;
      case EnemyType.Medium:
        spriteName = 'enemy.png';
        textureSize = Vector2.all(64);
        hitboxRadius = 16;
        moveSpeed = 80;
        health = setMediumHealth();
        attackCooldown = 1;
        getOutOfSpawn = 1;
        break;
      case EnemyType.Big:
        spriteName = 'enemy_big.png';
        textureSize = Vector2.all(128);
        hitboxRadius = 32;
        moveSpeed = 50;
        health = 30;
        attackCooldown = 1;
        getOutOfSpawn = 3;
        break;
    }
    size = textureSize;
  }

  @override
  void update(double dt) {
    if (game.startGame) {
      selfDestruct -= dt;
      getOutOfSpawn -= dt;
      if (ignoreCorner) {
        ignoreCornerCooldown -= dt;
      }
      directionOfPlayer = determineDirectionOfPlayer(player, this);
      _updateMovement(dt);
      if (getOutOfSpawn <= 0) {
        _handleCollisions(dt);
      }
      if (enemyType == EnemyType.Big && shootCooldown <= 0) {
        _shoot();
      }
      _handleHealth();
      attackCooldown -= dt;
      shootCooldown -= dt;
      //print(followPlayer);
      //print(followCornerCooldown);
      if (ignoreCornerCooldown <= 0) {
        ignoreCorner = false;
        ignoreCornerCooldown = 0.3;
      }
      //print(ignoreCornerCooldown);
      //print(ignoreCorner);
    }
    super.update(dt);
  }

  void _updateMovement(double dt) {
    followCornerCooldown -= dt;
    if (getOutOfSpawn > 0) {
      movementDirection = initialMoveDirection;
    } else {
      if (followPlayer) {
        movementDirection = directionOfPlayer;
        if (enemyType == EnemyType.Big) {
          followCornerCooldown = 6;
        } else {
          followCornerCooldown = 2;
        }
      }
      if (followPlayer == false) {
        movementDirection = determineDirectionOfCorner(cornerToFollow, this);
        //print('Following Corner');

        if ((position - cornerToFollow).length < 2 ||
            followCornerCooldown < 0) {
          followPlayer = true;
          ignoreCorner = true;
        }
      }
    }
    velocity = movementDirection * moveSpeed;
    position += velocity * dt;
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is BasicEnemy && intersectionPoints.length == 2) {
      final mid =
          (intersectionPoints.elementAt(0) + intersectionPoints.elementAt(1)) /
          2;

      final collisionNormal = absoluteCenter - mid;
      final separationDistance = (hitboxRadius) - collisionNormal.length + 1;
      collisionNormal.normalize();

      position += collisionNormal.scaled(separationDistance);
      for (final block in collisionBlocks) {
        if (checkCollision(this, block)) {
          position -= collisionNormal.scaled(separationDistance);
          break;
        }
      }
    }
    if (other is Player && intersectionPoints.length == 2) {
      if (other.isVisible) {
        final mid =
            (intersectionPoints.elementAt(0) +
                intersectionPoints.elementAt(1)) /
            2;

        final collisionNormal = absoluteCenter - mid;
        final separationDistance = (hitboxRadius) - collisionNormal.length + 1;
        collisionNormal.normalize();

        position += collisionNormal.scaled(separationDistance);
        for (final block in collisionBlocks) {
          if (checkCollision(this, block)) {
            position -= collisionNormal.scaled(separationDistance);
            break;
          }
        }
      }
    }
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

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) async {
    if (other is Projectile && other.shooter == Shooter.Player) {
      health -= other.damage;
      other.hitCounter += 1;
      await SoLoud.instance.play(game.gotHitSoundEnemy);
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

  void _handleCollisions(double dt) {
    int collisionCounter = 0;
    for (final block in collisionBlocks) {
      if (block.interactionType == InteractionType.None) {
        if (checkCollision(this, block)) {
          _handleHorizontalCollisions(dt, block);
          _handleVerticalCollisons(dt, block);
          collisionCounter += 1;
        }
      }
      if (collisionCounter == 2) {
        break;
      }
    }
  }

  void _handleHorizontalCollisions(double dt, CollisionBlock block) {
    if (isCollisionHorizontal(this, block, dt)) {
      //if (followCornerCooldown < 0) {
      switch (block.extendedCorners.length) {
        case 0:
          _handleOneCornerHorizontal(block);
        case 2:
          _handleTwoCornerHorizontal(block);
          break;
        case 3:
          _handleThreeCornerHorizontal(block);
          break;
        case 4:
          _handleFourCornerHorizontal(block);
          break;
        default:
      }

      //}
      if (velocity.x > 0) {
        velocity.x = 0;
        position.x = block.x - this.width / 2;
      } else if (velocity.x < 0) {
        velocity.x = 0;
        position.x = block.x + block.width + this.width / 2;
      }
    }
  }

  void _handleOneCornerHorizontal(CollisionBlock block) {
    if (!ignoreCorner) {
      followPlayer = false;
    }
    double yToCompare = 0;
    switch (block.blockType) {
      case BlockType.DownRight:
      case BlockType.UpRight:
        yToCompare =
            (player.x - block.position.x) * block.comparisonVector.y +
            block.position.y;
        if (yToCompare > player.y) {
          cornerToFollow = Vector2(
            position.x,
            position.y - block.height,
          ); // goUp
        } else {
          cornerToFollow = Vector2(
            position.x,
            position.y + block.height,
          ); //goDown
        }

        break;
      default:
    }
  }

  void _handleTwoCornerHorizontal(CollisionBlock block) {
    if (!ignoreCorner) {
      followPlayer = false;
    }
    switch (block.blockType) {
      case BlockType.Left:
        if (velocity.y > 0) {
          cornerToFollow = block.extendedCorners[1] + size / 1.5;
        } else {
          cornerToFollow = block.extendedCorners[0];
          cornerToFollow += Vector2(size.x, -size.y) / 1.5;
        }
      case BlockType.Right:
        if (velocity.y > 0) {
          cornerToFollow = block.extendedCorners[1];
          cornerToFollow += Vector2(-size.x, size.y) / 1.5;
        } else {
          cornerToFollow = block.extendedCorners[0] - size / 1.5;
        }
      case BlockType.Top:
        if (velocity.x > 0) {
          cornerToFollow = block.extendedCorners[0];
          cornerToFollow += Vector2(-size.x / 2, size.y / 1.5);
        } else {
          cornerToFollow =
              block.extendedCorners[1] + Vector2(size.x / 2, size.y / 1.5);
        }
      case BlockType.Bottom:
        if (velocity.x > 0) {
          cornerToFollow =
              block.extendedCorners[0] - Vector2(size.x / 2, size.y / 1.5);
        } else {
          cornerToFollow = block.extendedCorners[1];
          cornerToFollow += Vector2(size.x / 2, -size.y / 1.5);
        }
        break;
      default:
    }
  }

  void _handleThreeCornerHorizontal(CollisionBlock block) {
    if (!ignoreCorner) {
      followPlayer = false;
    }
    switch (block.blockType) {
      case BlockType.BottomLeft:
        if (velocity.x > 0) {
          cornerToFollow.x = block.extendedCorners[0].x - size.x / 2;
          cornerToFollow.y = block.extendedCorners[0].y - size.y / 1.5;
        } else {
          if (velocity.y > 0) {
            cornerToFollow.x = block.extendedCorners[2].x + size.x / 2;
            cornerToFollow.y = block.extendedCorners[2].y + size.y / 1.5;
          } else {
            cornerToFollow = block.extendedCorners[1];
            cornerToFollow += Vector2(size.x, -size.y) / 1.5;
          }
        }
      case BlockType.TopLeft:
        if (velocity.x > 0) {
          cornerToFollow.x = block.extendedCorners[2].x - size.x / 2;
          cornerToFollow.y = block.extendedCorners[2].y + size.y / 1.5;
        } else {
          if (velocity.y > 0) {
            cornerToFollow = block.extendedCorners[1] + size / 1.5;
          } else {
            cornerToFollow.x = block.extendedCorners[0].x + size.x / 2;
            cornerToFollow.y = block.extendedCorners[0].y - size.y / 1.5;
            ;
          }
        }
      case BlockType.TopRight:
        if (velocity.x < 0) {
          cornerToFollow.x = block.extendedCorners[0].x + size.x / 2;
          cornerToFollow.y = block.extendedCorners[0].y + size.y / 1.5;
        } else {
          if (velocity.y > 0) {
            cornerToFollow = block.extendedCorners[1];
            cornerToFollow += Vector2(-size.x, size.y) / 1.5;
          } else {
            cornerToFollow.x = block.extendedCorners[2].x - size.x / 2;
            cornerToFollow.y = block.extendedCorners[2].y - size.y / 1.5;
          }
        }
      case BlockType.BottomRight:
        if (velocity.x < 0) {
          cornerToFollow.x = block.extendedCorners[2].x + size.x / 2;
          cornerToFollow.y = block.extendedCorners[2].y - size.y / 1.5;
        } else {
          if (velocity.y > 0) {
            cornerToFollow.x = block.extendedCorners[0].x - size.x / 2;
            cornerToFollow.y = block.extendedCorners[0].y + size.y / 1.5;
          } else {
            cornerToFollow = block.extendedCorners[1] - size / 1.5;
          }
        }

        break;
      default:
    }
  }

  void _handleFourCornerHorizontal(block) {
    if (!ignoreCorner) {
      followPlayer = false;
    }
    if (velocity.x > 0) {
      if (velocity.y > 0) {
        cornerToFollow.x = block.extendedCorners[3].x - size.x / 2;
        cornerToFollow.y = block.extendedCorners[3].y + size.y / 1.5;
      } else {
        cornerToFollow.x = block.extendedCorners[0].x - size.x / 2;
        cornerToFollow.y = block.extendedCorners[0].y - size.y / 1.5;
      }
    } else {
      if (velocity.y > 0) {
        cornerToFollow.x = block.extendedCorners[2].x + size.x / 2;
        cornerToFollow.y = block.extendedCorners[2].y + size.y / 1.5;
      } else {
        cornerToFollow.x = block.extendedCorners[1].x + size.x / 2;
        cornerToFollow.y = block.extendedCorners[1].y - size.y / 1.5;
      }
    }
  }

  void _handleVerticalCollisons(double dt, CollisionBlock block) {
    if (isCollisionVertical(this, block, dt)) {
      //if (followCornerCooldown < 0) {
      switch (block.extendedCorners.length) {
        case 0:
          _handleOneCornerVertical(block);
        case 2:
          _handleTwoCornerVertical(block);
          break;
        case 3:
          _handleThreeCornerVertical(block);
          break;
        case 4:
          _handleFourCornerVertical(block);
          break;
        default:
      }
      // }
      if (velocity.y > 0) {
        velocity.y = 0;
        position.y = block.y - this.height / 2;
      } else if (velocity.y < 0) {
        velocity.y = 0;
        position.y = block.y + block.height + this.height / 2;
      }
    }
  }

  void _handleOneCornerVertical(CollisionBlock block) {
    if (!ignoreCorner) {
      followPlayer = false;
    }
    double yToCompare = 0;
    switch (block.blockType) {
      case BlockType.DownRight:
        //print('DownRightVertical + $directionOfPlayer');

        yToCompare =
            (player.x - block.position.x) * block.comparisonVector.y +
            block.position.y;
        if (yToCompare > player.y) {
          cornerToFollow = Vector2(
            position.x + block.width,
            position.y,
          ); // goRight
        } else {
          cornerToFollow = Vector2(
            position.x - block.width,
            position.y,
          ); //goLeft
        }

      case BlockType.UpRight:
        yToCompare =
            (player.x - block.position.x) * block.comparisonVector.y +
            block.position.y;
        if (yToCompare > player.y) {
          cornerToFollow = Vector2(
            position.x - block.width,
            position.y,
          ); //goLeft
        } else {
          cornerToFollow = Vector2(
            position.x + block.width,
            position.y,
          ); // goRight
        }
        break;
      default:
    }
  }

  void _handleTwoCornerVertical(CollisionBlock block) {
    if (!ignoreCorner) {
      followPlayer = false;
    }
    switch (block.blockType) {
      case BlockType.Left:
        if (velocity.y > 0) {
          cornerToFollow =
              block.extendedCorners[0] + Vector2(size.x / 1.5, -size.y / 2);
        } else {
          cornerToFollow =
              block.extendedCorners[1] + Vector2(size.x / 1.5, size.y / 2);
        }
      case BlockType.Right:
        if (velocity.y > 0) {
          cornerToFollow =
              block.extendedCorners[0] - Vector2(size.x / 1.5, size.y / 2);
        } else {
          cornerToFollow =
              block.extendedCorners[1] + Vector2(-size.x / 1.5, size.y / 2);
        }
      case BlockType.Top:
        if (velocity.x > 0) {
          cornerToFollow = block.extendedCorners[1] + size / 1.5;
        } else {
          cornerToFollow =
              block.extendedCorners[0] + Vector2(-size.x, size.y) / 1.5;
        }
      case BlockType.Bottom:
        if (velocity.x > 0) {
          cornerToFollow =
              block.extendedCorners[1] + Vector2(size.x, -size.y) / 1.5;
        } else {
          cornerToFollow = block.extendedCorners[0] - size / 1.5;
        }
        break;
      default:
    }
  }

  void _handleThreeCornerVertical(CollisionBlock block) {
    if (!ignoreCorner) {
      followPlayer = false;
    }
    switch (block.blockType) {
      case BlockType.BottomLeft:
        if (velocity.y < 0) {
          cornerToFollow.x = block.extendedCorners[2].x + size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[2].y + size.y / 2;
        } else if (velocity.x > 0) {
          cornerToFollow =
              block.extendedCorners[1] + Vector2(size.x, -size.y) / 1.5;
        } else {
          cornerToFollow.x = block.extendedCorners[0].x - size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[0].y - size.y / 2;
        }

      case BlockType.TopLeft:
        if (velocity.y > 0) {
          cornerToFollow.x = block.extendedCorners[0].x + size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[0].y - size.y / 2;
        } else if (velocity.x > 0) {
          cornerToFollow = block.extendedCorners[1] + size / 1.5;
        } else {
          cornerToFollow.x = block.extendedCorners[2].x - size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[2].y + size.y / 2;
        }
      case BlockType.TopRight:
        if (velocity.y > 0) {
          cornerToFollow.x = block.extendedCorners[2].x - size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[2].y - size.y / 2;
        } else if (velocity.x > 0) {
          cornerToFollow.x = block.extendedCorners[0].x + size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[0].y + size.y / 2;
        } else {
          cornerToFollow =
              block.extendedCorners[1] + Vector2(-size.x, size.y) / 1.5;
        }
      case BlockType.BottomRight:
        if (velocity.y < 0) {
          cornerToFollow.x = block.extendedCorners[0].x - size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[0].y + size.y / 2;
        } else if (velocity.x > 0) {
          cornerToFollow.x = block.extendedCorners[2].x + size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[2].y - size.y / 2;
        } else {
          cornerToFollow = block.extendedCorners[1] - size / 1.5;
        }
      default:
    }
  }

  void _handleFourCornerVertical(block) {
    if (!ignoreCorner) {
      followPlayer = false;
    }
    if (velocity.y > 0) {
      if (velocity.x > 0) {
        cornerToFollow.x = block.extendedCorners[1].x + size.x / 1.5;
        cornerToFollow.y = block.extendedCorners[1].y - size.y / 2;
      } else {
        cornerToFollow.x = block.extendedCorners[0].x - size.x / 1.5;
        cornerToFollow.y = block.extendedCorners[0].y - size.y / 2;
      }
    } else {
      if (velocity.x > 0) {
        cornerToFollow.x = block.extendedCorners[2].x + size.x / 1.5;
        cornerToFollow.y = block.extendedCorners[2].y + size.y / 2;
      } else {
        cornerToFollow.x = block.extendedCorners[3].x - size.x / 1.5;
        cornerToFollow.y = block.extendedCorners[3].y + size.y / 2;
      }
    }
  }

  void _handleHealth() {
    if (health <= 0) {
      game.enemyCount -= 1;
      game.world1.enemiesDefeated += 1;
      int worth = 1;
      if (game.keyCanSpawn && game.world1.tileMapName == 'Level1.tmx') {
        int spawnParlay = random.nextInt(game.keySpawnrate);
        if (spawnParlay == 1) {
          worth = 0;
        }
      }
      Item loot = Item(position: position, worth: worth);
      game.world1.add(loot);
      game.world1.items.add(loot);
      game.world1.remove(this);
    } else if (game.world1.tileMapName == 'Stamina.tmx' &&
        enemyType == EnemyType.Small &&
        selfDestruct <= 0) {
      game.enemyCount -= 1;
      game.world1.remove(this);
    }
  }

  double setMediumHealth() {
    double initialHealth = 1;
    switch (game.doorsOpened) {
      case 0:
      case 1:
      case 2:
        initialHealth = 1;
        break;

      case 3:
        initialHealth = 20;
        break;

      default:
    }
    return initialHealth;
  }

  void _shoot() async {
    game.world1.add(
      Projectile(
        position: position,
        moveDirection: directionOfPlayer,
        shooter: Shooter.Enemy,
      ),
    );
    await SoLoud.instance.play(game.shootSoundEnemy);
    shootCooldown = 5;
  }
}
