import 'dart:async';

import 'package:flame/components.dart';

import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/components/pressure_plate.dart';
import 'package:survivor_test/components/spawners.dart';
import 'package:survivor_test/survivor_test.dart';

class Level extends World with HasGameReference<SurvivorTest> {
  late TiledComponent level;
  final Player player;
  final String tileMapName;
  Level({required this.player, required this.tileMapName});

  int enemiesDefeated = 0;

  List<CollisionBlock> collisionBlocks = [];
  List<PressurePlate> pressurePlates = [];

  List<Item> items = [];

  bool dontFollowVertically = false;
  bool dontFollowHorizontally = false;

  late AudioSource Level1BGM;
  late AudioSource HealthBGM;
  late AudioSource StaminaBGM;
  late AudioSource DamageBGM;

  @override
  FutureOr<void> onLoad() async {
    //debugMode = true;
    priority = -1;
    level = await TiledComponent.load(tileMapName, Vector2.all(16));
    add(level);
    _trackVisitedWorlds();
    _addCollisions();
    _addSpawners();
    _addPressurePlates();
    _changeBGM();
    _setInitialCameraPosition();
    player.isVisible = true;
    player.isDashing = false;
    player.lightningBalls = [];
    super.onLoad();
  }

  void _trackVisitedWorlds() {
    switch (tileMapName) {
      case 'Stamina.tmx':
        game.hasBeenToStamina = true;
        game.maxEnemyCount = 2;
        break;
      case 'Health.tmx':
        game.hasBeenToHealth = true;
        game.maxEnemyCount = 8;
        break;
      case 'Damage.tmx':
        game.hasBeenToDamage = true;
        game.maxEnemyCount = 3;
        break;
      default:
        game.resetMaxEnemyCount();
    }
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
              interactionType: InteractionType.Portal,
              destinationName: collision.name,
            );
            collisionBlocks.add(portal);
            add(portal);
          case 'Damage_Shop':
            final damageShop = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              interactionType: InteractionType.DamageShop,
            );
            collisionBlocks.add(damageShop);
            add(damageShop);
            break;
          case 'Health_Shop':
            final healthShop = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              interactionType: InteractionType.HealthShop,
            );
            collisionBlocks.add(healthShop);
            add(healthShop);
            break;
          case 'Stamina_Shop':
            final staminaShop = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              interactionType: InteractionType.StaminaShop,
            );
            collisionBlocks.add(staminaShop);
            add(staminaShop);
            break;
          case 'NoCorners':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.NoCorners,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Down_Right':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.DownRight,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Up_Right':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.UpRight,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Top':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.Top,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Left':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.Left,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Right':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.Right,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Bottom':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.Bottom,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Bottom_Left':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.BottomLeft,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Bottom_Right':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.BottomRight,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Top_Right':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.TopRight,
            );
            collisionBlocks.add(block);
            add(block);
            break;
          case 'Top_Left':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              blockType: BlockType.TopLeft,
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
    final spawnersLayer = level.tileMap.getLayer<ObjectGroup>('Spawners');
    if (spawnersLayer != null) {
      for (final instance in spawnersLayer.objects) {
        Vector2 spawnDirection = Vector2.all(1);
        switch (instance.class_) {
          case 'Down_Right':
            spawnDirection = Vector2.all(1);
            break;
          case 'Down_Left':
            spawnDirection = Vector2(-1, 1);
            break;
          case 'Up_Left':
            spawnDirection = Vector2.all(-1);
            break;
          case 'Up_Right':
            spawnDirection = Vector2(1, -1);
        }
        final spawner = Spawner(
          position: Vector2(instance.x, instance.y),
          worldName: tileMapName,
          spawnDirection: spawnDirection,
          size: instance.size,
        );
        add(spawner);
      }
    }
  }

  void _addPressurePlates() {
    if (tileMapName == 'Stamina.tmx') {
      final pressurePlatesLayer = level.tileMap.getLayer<ObjectGroup>(
        'Pressure_Plates',
      );
      if (pressurePlatesLayer != null) {
        for (final instance in pressurePlatesLayer.objects) {
          bool inside = false;
          if (instance.class_ == 'Inside') {
            inside = true;
          }
          final pressurePlate = PressurePlate(
            position: Vector2(instance.x, instance.y),
            size: instance.size,
            inside: inside,
          );
          pressurePlates.add(pressurePlate);
          add(pressurePlate);
        }
      }
    }
  }

  void _changeBGM() async {
    switch (tileMapName) {
      case 'Level1.tmx':
        Level1BGM = await SoLoud.instance.loadAsset(
          'assets/audio/Sunlight Through Leaves.mp3',
        );
        await SoLoud.instance.play(Level1BGM, looping: true);
        break;
      case 'Health.tmx':
        HealthBGM = await SoLoud.instance.loadAsset(
          'assets/audio/Gentle Breeze.mp3',
        );
        await SoLoud.instance.play(HealthBGM, looping: true);
        break;
      case 'Damage.tmx':
        DamageBGM = await SoLoud.instance.loadAsset(
          'assets/audio/Evening Harmony.mp3',
        );
        await SoLoud.instance.play(DamageBGM, looping: true);
        break;
      case 'Stamina.tmx':
        StaminaBGM = await SoLoud.instance.loadAsset(
          'assets/audio/Golden Gleam.mp3',
        );
        await SoLoud.instance.play(StaminaBGM, looping: true);
        break;
      default:
    }
  }

  void stopBGM() {
    switch (tileMapName) {
      case 'Level1.tmx':
        SoLoud.instance.disposeSource(Level1BGM);

        break;
      case 'Health.tmx':
        SoLoud.instance.disposeSource(HealthBGM);
        break;
      case 'Damage.tmx':
        SoLoud.instance.disposeSource(DamageBGM);
        break;
      case 'Stamina.tmx':
        SoLoud.instance.disposeSource(StaminaBGM);
        break;
      case 'Bossroom':
        SoLoud.instance.disposeSource(game.bossBGM);
        SoLoud.instance.disposeSource(game.victorySound);
        SoLoud.instance.disposeSource(game.introRoarSound);
      default:
    }
  }

  @override
  void update(double dt) {
    updateCameraPosition();
    super.update(dt);
  }

  void updateCameraPosition() {
    if ((player.position.x > level.width - game.size.x / 2 - 10) ||
        (player.position.x < game.size.x / 2 + 10)) {
      dontFollowHorizontally = true;
    }
    if ((player.position.y > level.height - game.size.y / 2 - 10) ||
        (player.position.y < game.size.y / 2 + 10)) {
      dontFollowVertically = true;
    }
    if (dontFollowHorizontally && dontFollowVertically) {
      game.camera.stop();
    } else if (dontFollowHorizontally) {
      game.camera.follow(player, verticalOnly: true);
    } else if (dontFollowVertically) {
      game.camera.follow(player, horizontalOnly: true);
    } else {
      game.camera.follow(player);
    }
    dontFollowHorizontally = false;
    dontFollowVertically = false;
  }

  void _setInitialCameraPosition() {
    switch (tileMapName) {
      case 'Level1.tmx':
        game.camera.follow(player);
        break;
      case 'Health.tmx':
        game.camera.moveTo(Vector2(game.size.x / 2, 496));
        break;
      case 'Stamina.tmx':
        game.camera.moveTo(Vector2(690, game.size.y / 2));
        break;
      case 'Damage.tmx':
        game.camera.moveTo(Vector2(level.width - game.size.x / 2, 432));
        break;
      case 'Bossroom.tmx':
        game.camera.moveTo(Vector2(608, level.height - game.size.y / 2));
      default:
    }
  }
}
