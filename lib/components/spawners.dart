import 'dart:async';

import 'package:flame/components.dart';
import 'package:survivor_test/actors/basic_enemy.dart';

import 'package:survivor_test/survivor_test.dart';

class Spawner extends PositionComponent with HasGameReference<SurvivorTest> {
  final double spawnerID;
  Spawner({required position, required this.spawnerID})
    : super(position: position);

  double cooldown = 3;
  late int enemyCount;

  @override
  FutureOr<void> onLoad() {
    game.world1.add(this);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    enemyCount = game.world1.enemyCount;
    if (cooldown <= 0 && enemyCount <= 12) {
      BasicEnemy basicEnemy = BasicEnemy(position: position);
      game.world1.add(basicEnemy);
      game.world1.basicEnemies.add(basicEnemy);
      resetCooldown();
      //game.world1.enemyCount += 1; untested!!!
    }
    cooldown -= dt;
    super.update(dt);
  }

  void resetCooldown() {
    cooldown = 10;
  }
}
