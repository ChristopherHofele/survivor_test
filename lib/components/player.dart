import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:survivor_test/survivor_test.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<SurvivorTest>, TapCallbacks, CollisionCallbacks {
  Player({position}) : super(position: position, size: Vector2(64, 64));

  double moveSpeed = 100;
  double horizontalMovement = 0;
  double verticalMovement = 0;
  Vector2 velocity = Vector2.zero();

  @override
  void onLoad() {
    priority = 1;
    debugMode = true;
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('monster.png'),
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2(64, 60),
        stepTime: 0.12,
      ),
    );
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    _updatePlayerMovement(dt);
    super.update(dt);
  }

  void _updatePlayerMovement(double dt) {
    velocity.x = horizontalMovement * moveSpeed;
    position.x = velocity.x * dt;
    velocity.y = verticalMovement * moveSpeed;
    position.y = velocity.y * dt;
  }
}
