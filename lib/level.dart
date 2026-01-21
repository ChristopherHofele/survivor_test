import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:survivor_test/actors/basic_enemy.dart';
import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/components/cookie.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/components/spawners.dart';
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
  List<Cookie> cookies = [];
  int enemyCount = 0;

  @override
  FutureOr<void> onLoad() async {
    //debugMode = true;
    priority = -1;
    level = await TiledComponent.load('Level1.tmx', Vector2.all(16));
    add(level);
    _addCollisions();
    //_addInitialEnemies();
    _addSpawners();

    super.onLoad();
  }

  void _addCollisions() {
    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');
    if (collisionsLayer != null) {
      for (final collision in collisionsLayer.objects) {
        switch (collision.class_) {
          case 'Damage_Shop':
            final damageShop = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              shopType: ShopType.DamageShop,
            );
            collisionBlocks.add(damageShop);
            add(damageShop);
            break;
          case 'Health_Shop':
            final healthShop = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              shopType: ShopType.HealthShop,
            );
            collisionBlocks.add(healthShop);
            add(healthShop);
            break;
          case 'Stamina_Shop':
            final staminaShop = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              shopType: ShopType.StaminaShop,
            );
            collisionBlocks.add(staminaShop);
            add(staminaShop);
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

  /*void _addInitialEnemies() {
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
  }*/

  void _addSpawners() {
    double spawnerID = 0;
    final spawnersLayer = level.tileMap.getLayer<ObjectGroup>('Spawners');
    if (spawnersLayer != null) {
      for (final instance in spawnersLayer.objects) {
        final spawner = Spawner(
          position: Vector2(instance.x, instance.y),
          spawnerID: spawnerID,
          size: instance.size,
        );
        spawnerID += 1;
        add(spawner);
      }
    }
  }
}
