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
  final String tileMapName;
  Level({required this.player, required this.tileMapName});
  List<CollisionBlock> collisionBlocks = [];
  List<BasicEnemy> basicEnemies = [];
  List<Cookie> cookies = [];

  @override
  FutureOr<void> onLoad() async {
    //debugMode = true;
    priority = -1;
    level = await TiledComponent.load(tileMapName, Vector2.all(16));
    add(level);
    _addCollisions();
    _addSpawners();

    super.onLoad();
  }

  void _addCollisions() {
    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');
    if (collisionsLayer != null) {
      for (final collision in collisionsLayer.objects) {
        switch (collision.class_) {
          case 'Portal':
            final portal = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              destinationName: collision.name,
            );
            collisionBlocks.add(portal);
            add(portal);
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
          case 'Top':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              cornerType: CornerType.Top,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Left':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              cornerType: CornerType.Left,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Right':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              cornerType: CornerType.Right,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Bottom':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              cornerType: CornerType.Bottom,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Bottom_Left':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              cornerType: CornerType.BottomLeft,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Bottom_Right':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              cornerType: CornerType.BottomRight,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Top_Right':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              cornerType: CornerType.TopRight,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Top_Left':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              cornerType: CornerType.TopLeft,
            );
            collisionBlocks.add(block);
            add(block);
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
