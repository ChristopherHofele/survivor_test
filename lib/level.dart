import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/survivor_test.dart';

class Level extends World with HasGameReference<SurvivorTest> {
  late TiledComponent level;
  final Player player;
  Level({required this.player});
  List<CollisionBlock> collisionBlocks = [];

  @override
  FutureOr<void> onLoad() async {
    priority = -1;
    level = await TiledComponent.load('Level1.tmx', Vector2.all(16));
    add(level);
    _addCollisions();
    super.onLoad();
  }

  void _addCollisions() {
    debugMode = true;
    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');
    if (collisionsLayer != null) {
      for (final collision in collisionsLayer.objects) {
        switch (collision.class_) {
          case 'Shop':
            final shop = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              isShop: true,
            );
            collisionBlocks.add(shop);
            add(shop);
            break;
          default:
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
            );
            collisionBlocks.add(block);
            add(block);
        }
      }
    }
    player.collisionBlocks = collisionBlocks;
  }
}
