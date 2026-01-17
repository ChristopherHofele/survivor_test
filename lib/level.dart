import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:survivor_test/actors/basic_enemy.dart';
import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/survivor_test.dart';

class Level extends World with HasGameReference<SurvivorTest> {
  late TiledComponent level;
  final Player player;
  late BasicEnemy basicEnemy1;
  late BasicEnemy basicEnemy2;
  late BasicEnemy basicEnemy3;
  late BasicEnemy basicEnemy4;
  Level({required this.player});
  List<CollisionBlock> collisionBlocks = [];
  List<BasicEnemy> basicEnemies = [];

  @override
  FutureOr<void> onLoad() async {
    priority = -1;
    level = await TiledComponent.load('Level1.tmx', Vector2.all(16));
    add(level);
    _addCollisions();
    basicEnemy1 = BasicEnemy(position: Vector2(250, 250));
    basicEnemies.add(basicEnemy1);
    add(basicEnemy1);
    basicEnemy2 = BasicEnemy(position: Vector2(-250, -250));
    add(basicEnemy2);
    basicEnemies.add(basicEnemy2);
    basicEnemy3 = BasicEnemy(position: Vector2(450, -350));
    add(basicEnemy3);
    basicEnemies.add(basicEnemy3);
    basicEnemy4 = BasicEnemy(position: Vector2(250, -250));
    add(basicEnemy4);
    basicEnemies.add(basicEnemy4);
    player.basicEnemies = basicEnemies;

    super.onLoad();
  }

  void _addCollisions() {
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
