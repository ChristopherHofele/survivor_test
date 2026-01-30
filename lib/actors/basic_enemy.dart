import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/level.dart';
import 'package:survivor_test/survivor_test.dart';

enum EnemyType { Small, Medium, Big }

class BasicEnemy extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest>, CollisionCallbacks {
  EnemyType enemyType;
  BasicEnemy({required position, required this.enemyType})
    : super(position: position, size: Vector2.all(64), anchor: Anchor.center);

  late double moveSpeed;
  late double health;
  late double attackCooldown;
  late double hitboxRadius;
  double followCornerCooldown = 0.3;
  double getOutOfSpawn = 3;

  var random = Random();

  late final Player player;
  late final Level level;

  Vector2 movementDirection = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  Vector2 cornerToFollow = Vector2.zero();
  late Vector2 textureSize;

  List<CollisionBlock> collisionBlocks = [];
  List<BasicEnemy> basicEnemies = [];

  bool followPlayer = true;
  bool first = false;

  late String spriteName;

  @override
  void onLoad() {
    _initializeEnemyType();
    if (game.enemyCount == 0) {
      first = true;
    }
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
        moveSpeed = 120;
        health = 1;
        attackCooldown = 1;
        break;
      case EnemyType.Medium:
        spriteName = 'enemy.png';
        textureSize = Vector2.all(64);
        hitboxRadius = 16;
        moveSpeed = 80;
        health = 1;
        attackCooldown = 1;
        break;
      case EnemyType.Big:
        spriteName = 'enemy_big.png';
        textureSize = Vector2.all(128);
        hitboxRadius = 32;
        moveSpeed = 50;
        health = 30;
        attackCooldown = 5;
        break;
    }
    size = textureSize;
  }

  @override
  void update(double dt) {
    print(followPlayer);
    if (game.startGame) {
      getOutOfSpawn -= dt;
      _updateMovement(dt);
      if (getOutOfSpawn <= 0) {
        _handleCollisions(dt);
      }
      if (enemyType == EnemyType.Big && attackCooldown <= 0) {
        game.world1.add(
          Projectile(
            position: position,
            moveDirection: movementDirection,
            shooter: Shooter.Enemy,
          ),
        );
        attackCooldown = 5;
      }
      basicEnemies = game.world1.basicEnemies;
      _handleHealth();
      attackCooldown -= dt;
    }
    super.update(dt);
  }

  void _updateMovement(double dt) {
    followCornerCooldown -= dt;
    if (followPlayer) {
      movementDirection = determineDirectionOfPlayer(player);
      if (enemyType == EnemyType.Big) {
        followCornerCooldown = 6;
      } else {
        followCornerCooldown = 2;
      }
      //print('followingPlayer');
    } else {
      movementDirection = determineDirectionOfCorner(cornerToFollow);
      //print('followingCorner');
      if ((position - cornerToFollow).length < 2 || followCornerCooldown < 0) {
        followPlayer = true;
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
    if (other is BasicEnemy && intersectionPoints.length == 2 ||
        other is Player && intersectionPoints.length == 2) {
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
      super.onCollision(intersectionPoints, other);
    }
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

  Vector2 determineDirectionOfPlayer(player) {
    Vector2 directionOfPlayer = Vector2.zero();
    directionOfPlayer.x = player.position.x - position.x;
    directionOfPlayer.y = player.position.y - position.y;
    directionOfPlayer.normalize();
    return directionOfPlayer;
  }

  Vector2 determineDirectionOfCorner(Vector2 corner) {
    Vector2 directionOfCorner = Vector2.zero();
    directionOfCorner.x = corner.x - position.x;
    directionOfCorner.y = corner.y - position.y;
    directionOfCorner.normalize();
    return directionOfCorner;
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
      if (block.extendedCorners.length == 2) {
        _handleTwoCornerHorizontal(block);
      } else if (block.extendedCorners.length == 3) {
        _handleThreeCornerHorizontal(block);
      } else if (block.extendedCorners.length == 4) {
        _handleFourCornerHorizontal(block);
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

  void _handleTwoCornerHorizontal(CollisionBlock block) {
    followPlayer = false;
    switch (block.blockType) {
      case BlockType.Left:
        if (velocity.y > 0) {
          cornerToFollow = block.extendedCorners[1] + size / 1.8;
        } else {
          cornerToFollow = block.extendedCorners[0];
          cornerToFollow += Vector2(size.x, -size.y) / 1.8;
        }
      case BlockType.Right:
        if (velocity.y > 0) {
          cornerToFollow = block.extendedCorners[1];
          cornerToFollow += Vector2(-size.x, size.y) / 1.8;
        } else {
          cornerToFollow = block.extendedCorners[0] - size / 1.8;
        }
      case BlockType.Top:
        if (velocity.x > 0) {
          cornerToFollow = block.extendedCorners[0];
          cornerToFollow += Vector2(-size.x, size.y) / 1.8;
        } else {
          cornerToFollow = block.extendedCorners[1] + size / 1.8;
        }
      case BlockType.Bottom:
        if (velocity.x > 0) {
          cornerToFollow = block.extendedCorners[0] - size / 1.8;
        } else {
          cornerToFollow = block.extendedCorners[1];
          cornerToFollow += Vector2(size.x, -size.y) / 1.8;
        }
        break;
      default:
    }
  }

  void _handleThreeCornerHorizontal(CollisionBlock block) {
    followPlayer = false;
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
            cornerToFollow += Vector2(size.x, -size.y) / 1.8;
          }
        }
      case BlockType.TopLeft:
        if (velocity.x > 0) {
          cornerToFollow.x = block.extendedCorners[2].x - size.x / 2;
          cornerToFollow.y = block.extendedCorners[2].y + size.y / 1.5;
        } else {
          if (velocity.y > 0) {
            cornerToFollow = block.extendedCorners[1] + size / 1.8;
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
            cornerToFollow += Vector2(-size.x, size.y) / 1.8;
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
            cornerToFollow = block.extendedCorners[1] - size / 1.8;
          }
        }

        break;
      default:
    }
  }

  void _handleFourCornerHorizontal(block) {
    followPlayer = false;
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
      if (block.extendedCorners.length == 2) {
        _handleTwoCornerVertical(block);
      } else if (block.extendedCorners.length == 3) {
        _handleThreeCornerVertical(block);
      } else if (block.extendedCorners.length == 4) {
        _handleFourCornerVertical(block);
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

  void _handleTwoCornerVertical(CollisionBlock block) {
    followPlayer = false;
    switch (block.blockType) {
      case BlockType.Left:
        if (velocity.y > 0) {
          cornerToFollow =
              block.extendedCorners[0] + Vector2(size.x, -size.y) / 1.8;
        } else {
          cornerToFollow = block.extendedCorners[1] + size / 1.8;
        }
      case BlockType.Right:
        if (velocity.y > 0) {
          cornerToFollow = block.extendedCorners[0] - size / 1.8;
        } else {
          cornerToFollow =
              block.extendedCorners[1] + Vector2(-size.x, size.y) / 1.8;
        }
      case BlockType.Top:
        if (velocity.x > 0) {
          cornerToFollow = block.extendedCorners[1] + size / 1.8;
        } else {
          cornerToFollow =
              block.extendedCorners[0] + Vector2(-size.x, size.y) / 1.8;
        }
      case BlockType.Bottom:
        if (velocity.x > 0) {
          cornerToFollow =
              block.extendedCorners[1] + Vector2(size.x, -size.y) / 1.8;
        } else {
          cornerToFollow = block.extendedCorners[0] - size / 1.8;
        }
        break;
      default:
    }
  }

  void _handleThreeCornerVertical(CollisionBlock block) {
    followPlayer = false;
    switch (block.blockType) {
      case BlockType.BottomLeft:
        if (velocity.y < 0) {
          cornerToFollow.x = block.extendedCorners[2].x + size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[2].y + size.y / 2;
        } else if (velocity.x > 0) {
          cornerToFollow =
              block.extendedCorners[1] + Vector2(size.x, -size.y) / 1.8;
        } else {
          cornerToFollow.x = block.extendedCorners[0].x - size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[0].y - size.y / 2;
        }

      case BlockType.TopLeft:
        if (velocity.y > 0) {
          cornerToFollow.x = block.extendedCorners[0].x + size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[0].y - size.y / 2;
        } else if (velocity.x > 0) {
          cornerToFollow = block.extendedCorners[1] + size / 1.8;
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
              block.extendedCorners[1] + Vector2(-size.x, size.y) / 1.8;
        }
      case BlockType.BottomRight:
        if (velocity.y < 0) {
          cornerToFollow.x = block.extendedCorners[0].x - size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[0].y + size.y / 2;
        } else if (velocity.x > 0) {
          cornerToFollow.x = block.extendedCorners[2].x + size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[2].y - size.y / 2;
        } else {
          cornerToFollow = block.extendedCorners[1] - size / 1.8;
        }
      default:
    }
  }

  void _handleFourCornerVertical(block) {
    followPlayer = false;
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
      int worth = 1;
      if (game.keyCanSpawn && game.world1.tileMapName == 'Level1.tmx') {
        int spawnParlay = random.nextInt(game.keySpawnrate);
        if (spawnParlay == 2) {
          worth = 0;
        }
      }
      Item loot = Item(position: position, worth: worth);
      game.world1.add(loot);
      game.world1.items.add(loot);
      game.world1.remove(this);
    }
  }
}
