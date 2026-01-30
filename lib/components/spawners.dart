import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:survivor_test/actors/basic_enemy.dart';

import 'package:survivor_test/survivor_test.dart';

class Spawner extends PositionComponent with HasGameReference<SurvivorTest> {
  final double spawnerID;
  Spawner({required position, required this.spawnerID, size})
    : super(position: position, size: size);

  double cooldown = 1;
  late int enemyCount;
  late Vector2 spawnLocation;
  var random = Random();
  late EnemyType enemyType;

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
      if (cooldown <= 0 && enemyCount < 1) {
        int enemyTypeChooser = 0; //random.nextInt(3);
        switch (enemyTypeChooser) {
          case 0:
            enemyType = EnemyType.Medium;
            break;
          case 1:
            enemyType = EnemyType.Big;
          case 2:
            enemyType = EnemyType.Small;
        }
        BasicEnemy basicEnemy = BasicEnemy(
          position: spawnLocation,
          enemyType: enemyType,
        );
        game.world1.add(basicEnemy);
        game.world1.basicEnemies.add(basicEnemy);
        resetCooldown();
        game.enemyCount += 1;
      }
      cooldown -= dt;
    }
    super.update(dt);
  }

  void resetCooldown() {
    cooldown = 3;
  }
}
