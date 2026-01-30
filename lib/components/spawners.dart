import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:survivor_test/actors/basic_enemy.dart';
import 'package:survivor_test/actors/boss_enemy.dart';

import 'package:survivor_test/survivor_test.dart';

class Spawner extends PositionComponent with HasGameReference<SurvivorTest> {
  String worldName;
  Spawner({required position, required this.worldName, size})
    : super(position: position, size: size);

  double cooldown = 3;
  int specialEnemySpawnrate = 20;
  late int enemyCount;
  late Vector2 spawnLocation;
  var random = Random();
  late EnemyType enemyType;
  bool spawnBoss = true;

  @override
  FutureOr<void> onLoad() {
    spawnLocation = Vector2(position.x + size.x / 2, position.y + size.y / 2);
    game.world1.add(this);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (game.startGame) {
      enemyCount = game.enemyCount;
      if (worldName == 'Bossroom.tmx') {
        if (spawnBoss) {
          BossEnemy bossEnemy = BossEnemy(position: spawnLocation);
          game.world1.add(bossEnemy);
          game.enemyCount += 1;
          spawnBoss = false;
        }
      } else {
        _spawnEnemies();
      }
    }
    cooldown -= dt;

    super.update(dt);
  }

  void _spawnEnemies() {
    if (cooldown <= 0 && enemyCount < game.maxEnemyCount) {
      _determineEnemyType();

      BasicEnemy basicEnemy = BasicEnemy(
        position: spawnLocation,
        enemyType: enemyType,
      );
      game.world1.add(basicEnemy);
      game.world1.basicEnemies.add(basicEnemy);
      game.enemyCount += 1;
      resetCooldown();
    }
  }

  void _determineEnemyType() {
    switch (worldName) {
      case 'Level1.tmx':
        enemyType = EnemyType.Medium;
        int enemyTypeChooser = random.nextInt(specialEnemySpawnrate);
        if (game.hasBeenToDamage && enemyTypeChooser == 2) {
          enemyType = EnemyType.Big;
        }
        if (game.hasBeenToStamina && enemyTypeChooser == 1) {
          enemyType = EnemyType.Small;
        }
        break;
      case 'Stamina.tmx':
        enemyType = EnemyType.Small;
        break;
      case 'Damage.tmx':
        enemyType = EnemyType.Big;
        break;
      case 'Health.tmx':
        enemyType = EnemyType.Medium;
        break;
      default:
    }
    /*int enemyTypeChooser = 0; //random.nextInt(3);
    switch (enemyTypeChooser) {
      case 0:
        enemyType = EnemyType.Medium;
        break;
      case 1:
        enemyType = EnemyType.Big;
      case 2:
        enemyType = EnemyType.Small;
    }*/
  }

  void resetCooldown() {
    cooldown = 3;
  }
}
