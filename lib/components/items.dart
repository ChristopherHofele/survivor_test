import 'dart:async';

import 'package:flame/components.dart';

import 'package:survivor_test/survivor_test.dart';

class Item extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest> {
  final int worth;
  late String worldName;
  Item({required position, this.worldName = '', this.worth = 1})
    : super(position: position - Vector2.all(25), size: Vector2.all(50));

  String spriteName = '';
  late int amount;
  late Vector2 textureSize;
  late double stepTime;

  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    _determineSprite();
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Items/Fruits/${this.spriteName}.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        textureSize: textureSize,
        stepTime: stepTime,
      ),
    );
    return super.onLoad();
  }

  void _determineSprite() {
    if (worth == 1) {
      spriteName = 'cookie';
      amount = 8;
      textureSize = Vector2.all(32);
      stepTime = 0.12;
    } else if (worth == 0) {
      spriteName = 'Key';
      amount = 25;
      textureSize = Vector2(10, 27);
      size = textureSize;
      stepTime = 0.12;
    } else {
      switch (worldName) {
        case 'Health.tmx':
          spriteName = 'Apple';
          break;
        case 'Stamina.tmx':
          spriteName = 'Bananas';
          break;
        case 'Damage.tmx':
          spriteName = 'Cherries';
          break;
        default:
      }
      amount = 17;
      textureSize = Vector2.all(32);
      stepTime = 0.12;
      position += Vector2.all(9);
    }
  }
}
