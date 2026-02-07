import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:survivor_test/survivor_test.dart';
import 'package:survivor_test/actors/player.dart';

class Melee extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest> {
  Vector2 meleeDirection;
  int strength;
  bool soundON;
  Melee({
    required position,
    required this.meleeDirection,
    required this.strength,
    required this.soundON,
  }) : super(position: position, size: Vector2(114, 64), anchor: Anchor.center);

  double damage = 20;
  double meleeDuration = 0.45;

  late Vector2 textureSize;
  late double xPositionOffset;

  late String spriteName;

  late RectangleHitbox hitboxBig;
  late RectangleHitbox hitboxRegular;

  @override
  FutureOr<void> onLoad() async {
    //debugMode = true;
    switch (game.world1.player.current) {
      case CharacterState.LevelOne:
        spriteName = 'MeleeOne.png';
        textureSize = Vector2(114, 64);
        xPositionOffset = 57;

        break;
      case CharacterState.LevelTwo:
        if (strength == 1) {
          size *= 2;
          spriteName = 'MeleeTwo.png';
          textureSize = Vector2(226, 128);
          xPositionOffset = 114;
        } else {
          spriteName = 'MeleeOne.png';
          textureSize = Vector2(114, 64);
          xPositionOffset = 57;
        }
        break;
      case CharacterState.LevelThree:
        if (strength == 2) {
          size *= 4;
          spriteName = 'MeleeThree.png';
          textureSize = Vector2(456, 256);
          xPositionOffset = 256;
        } else if (strength == 1) {
          size *= 2;
          spriteName = 'MeleeTwo.png';
          textureSize = Vector2(226, 128);
          xPositionOffset = 114;
        } else {
          spriteName = 'MeleeOne.png';
          textureSize = Vector2(114, 64);
          xPositionOffset = 57;
        }
        break;
      default:
    }
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache(spriteName),
      SpriteAnimationData.sequenced(
        amount: 5,
        textureSize: textureSize,
        stepTime: 0.1,
      ),
    );
    angle = atan2(meleeDirection.y, meleeDirection.x) - 1.57;
    hitboxBig = RectangleHitbox(collisionType: CollisionType.passive);
    hitboxBig.position.x -= xPositionOffset;
    add(hitboxBig);
    if (strength == 0) {
      hitboxRegular = RectangleHitbox(
        size: size / 2,
        collisionType: CollisionType.passive,
      );
      hitboxRegular.position.x += xPositionOffset / 2;
      add(hitboxRegular);
    }
    if (soundON) {
      game.slashSound.start();
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    meleeDuration -= dt;

    if (meleeDuration <= 0) {
      removeFromParent();
    }
    super.update(dt);
  }
}
