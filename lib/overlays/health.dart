import 'dart:async';

import 'package:flame/components.dart';
import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/survivor_test.dart';

enum HealthState { uninjured, injured }

class Heart extends SpriteGroupComponent<HealthState>
    with HasGameReference<SurvivorTest> {
  final int heartID;
  Heart({position, required this.heartID}) : super(position: position);

  late final Player player;
  @override
  FutureOr<void> onLoad() async {
    player = game.player;
    final uninjuredSprite = await game.loadSprite('HUD/heart.png');
    final injuredSprite = await game.loadSprite('HUD/heart_half.png');

    sprites = {
      HealthState.uninjured: uninjuredSprite,
      HealthState.injured: injuredSprite,
    };

    position = position;
    priority = 10;

    current = HealthState.uninjured;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (player.health / 100 < heartID) {
      current = HealthState.injured;
    } else {
      current = HealthState.uninjured;
    }

    super.update(dt);
  }
}
