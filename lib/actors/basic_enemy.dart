import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/actors/utils.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/components/cookie.dart';
import 'package:survivor_test/components/projectile.dart';
import 'package:survivor_test/level.dart';
import 'package:survivor_test/survivor_test.dart';

class BasicEnemy extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest>, CollisionCallbacks {
  BasicEnemy({position})
    : super(position: position, size: Vector2(64, 64), anchor: Anchor.center);

  double moveSpeed = 80;
  double health = 1;
  double followCornerCooldown = 0.3;
  double attackCooldown = 1;
  double getOutOfSpawn = 3;
  final double hitboxRadius = 16;

  late final Player player;
  late final Level level;

  Vector2 movementDirection = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  Vector2 cornerToFollow = Vector2.zero();

  List<CollisionBlock> collisionBlocks = [];
  List<BasicEnemy> basicEnemies = [];

  bool followPlayer = true;
  bool first = false;

  @override
  void onLoad() {
    //debugMode = true;
    if (game.enemyCount == 0) {
      first = true;
    }
    player = game.player;
    collisionBlocks = player.collisionBlocks;
    priority = 1;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('enemy.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(64, 64),
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

  @override
  void update(double dt) {
    if (game.startGame) {
      getOutOfSpawn -= dt;
      _updateMovement(dt);
      if (getOutOfSpawn <= 0) {
        _handleCollisions(dt);
      }
      basicEnemies = game.world1.basicEnemies;
      _handleHealth();
      attackCooldown -= dt;
    }
    super.update(dt);
  }

  void _updateMovement(double dt) {
    if (followPlayer) {
      movementDirection = determineDirectionOfPlayer(player);
      followCornerCooldown = 2;
      //print('followingPlayer');
    } else {
      movementDirection = determineDirectionOfCorner(cornerToFollow);
      followCornerCooldown -= dt;
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
    if (other is BasicEnemy ||
        other is Player && intersectionPoints.length == 2) {
      final mid =
          (intersectionPoints.elementAt(0) + intersectionPoints.elementAt(1)) /
          2;

      final collisionNormal = absoluteCenter - mid;
      final separationDistance = (16) - collisionNormal.length;
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
    if (other is Projectile) {
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
      if (block.shopType == ShopType.NoShop) {
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
    switch (block.cornerType) {
      case CornerType.Left:
        if (velocity.y > 0) {
          cornerToFollow = block.extendedCorners[1] + size / 1.8;
        } else {
          cornerToFollow = block.extendedCorners[0];
          cornerToFollow += Vector2(size.x, -size.y) / 1.8;
        }
      case CornerType.Right:
        if (velocity.y > 0) {
          cornerToFollow = block.extendedCorners[1];
          cornerToFollow += Vector2(-size.x, size.y) / 1.8;
        } else {
          cornerToFollow = block.extendedCorners[0] - size / 1.8;
        }
      case CornerType.Top:
        if (velocity.x > 0) {
          cornerToFollow = block.extendedCorners[0];
          cornerToFollow += Vector2(-size.x, size.y) / 1.8;
        } else {
          cornerToFollow = block.extendedCorners[1] + size / 1.8;
        }
      case CornerType.Bottom:
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
    switch (block.cornerType) {
      case CornerType.BottomLeft:
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
      case CornerType.TopLeft:
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
      case CornerType.TopRight:
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
      case CornerType.BottomRight:
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

  void _handleVerticalCollisons(double dt, CollisionBlock block) {
    if (isCollisionVertical(this, block, dt)) {
      //if (followCornerCooldown < 0) {
      if (block.extendedCorners.length == 2) {
        _handleTwoCornerVerticalal(block);
      } else if (block.extendedCorners.length == 3) {
        _handleThreeCornerVertical(block);
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

  void _handleTwoCornerVerticalal(CollisionBlock block) {
    followPlayer = false;
    switch (block.cornerType) {
      case CornerType.Left:
        if (velocity.y > 0) {
          cornerToFollow =
              block.extendedCorners[0] + Vector2(size.x, -size.y) / 1.8;
        } else {
          cornerToFollow = block.extendedCorners[1] + size / 1.8;
        }
      case CornerType.Right:
        if (velocity.y > 0) {
          cornerToFollow = block.extendedCorners[0] - size / 1.8;
        } else {
          cornerToFollow =
              block.extendedCorners[1] + Vector2(-size.x, size.y) / 1.8;
        }
      case CornerType.Top:
        if (velocity.x > 0) {
          cornerToFollow = block.extendedCorners[1] + size / 1.8;
        } else {
          cornerToFollow =
              block.extendedCorners[0] + Vector2(-size.x, size.y) / 1.8;
        }
      case CornerType.Bottom:
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
    switch (block.cornerType) {
      case CornerType.BottomLeft:
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

      case CornerType.TopLeft:
        if (velocity.y > 0) {
          cornerToFollow.x = block.extendedCorners[0].x + size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[0].y - size.y / 2;
        } else if (velocity.x > 0) {
          cornerToFollow = block.extendedCorners[1] + size / 1.8;
        } else {
          cornerToFollow.x = block.extendedCorners[2].x - size.x / 1.5;
          cornerToFollow.y = block.extendedCorners[2].y + size.y / 2;
        }
      case CornerType.TopRight:
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
      case CornerType.BottomRight:
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

  void _handleHealth() {
    if (health <= 0) {
      game.enemyCount -= 1;
      Cookie cookie = Cookie(position: position);
      game.world1.add(cookie);
      game.world1.cookies.add(cookie);
      game.world1.remove(this);
    }
  }
}
