import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';

import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/components/items.dart';
import 'package:survivor_test/components/collision_block.dart';
import 'package:survivor_test/components/fruit_tree.dart';
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

  // The special tree in upgrade rooms (null in rooms without one)
  FruitTree? tree;

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
    _setUpCamera();
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
    TiledObject? treeObject;
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
          case 'Tree':
            // Only a marker, not a wall: the tree is set up after the loop,
            // once the room's shop object (where the seed drops) is known
            treeObject = collision;
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
    if (treeObject != null) {
      _addTree(treeObject);
    }
  }

  void _addTree(TiledObject treeObject) {
    final seedType = roomSeeds[tileMapName];
    if (seedType == null) return;
    const shopTypes = {
      InteractionType.HealthShop,
      InteractionType.StaminaShop,
      InteractionType.DamageShop,
    };
    // The seed drops at the room's shop object (where the fruit used to be)
    for (final block in collisionBlocks) {
      if (shopTypes.contains(block.interactionType)) {
        tree = FruitTree(
          position: Vector2(treeObject.x, treeObject.y),
          size: Vector2(treeObject.width, treeObject.height),
          seedType: seedType,
          seedSpot: block.position,
        );
        add(tree!);
        return;
      }
    }
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
      case 'Bossroom.tmx':
        SoLoud.instance.disposeSource(game.bossBGM);
        SoLoud.instance.disposeSource(game.victorySound);
        SoLoud.instance.disposeSource(game.introRoarSound);
      default:
    }
  }

  // The camera follows the player but never shows anything outside the map
  void _setUpCamera() {
    game.camera.follow(player);
    _updateCameraBounds(game.size);
  }

  // The screen size can change (e.g. phone turning from portrait to
  // landscape), which changes how much of the map is visible
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _updateCameraBounds(size);
    }
  }

  // The camera's position is its centre, so it has to stay half a screen
  // away from each map edge. Zooming in shows less of the map, so the visible
  // area is the screen size divided by the zoom.
  // (Flame's setBounds(considerViewport: true) forgets about the zoom,
  // which is why we calculate this ourselves.)
  void _updateCameraBounds(Vector2 screenSize) {
    final halfVisible = screenSize / game.camera.viewfinder.zoom / 2;
    final (left, right) = _cameraRange(halfVisible.x, level.width);
    final (top, bottom) = _cameraRange(halfVisible.y, level.height);
    game.camera.setBounds(Rectangle.fromLTRB(left, top, right, bottom));
  }

  // Where the camera centre may be along one direction. If the map is
  // smaller than the screen in that direction, the camera stays centred.
  (double, double) _cameraRange(double halfVisible, double mapLength) {
    if (halfVisible * 2 >= mapLength) {
      return (mapLength / 2, mapLength / 2);
    }
    return (halfVisible, mapLength - halfVisible);
  }
}
