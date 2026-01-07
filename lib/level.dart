import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:survivor_test/survivor_test.dart';

class Level extends World with HasGameReference<SurvivorTest> {
  late TiledComponent level;

  @override
  FutureOr<void> onLoad() async {
    priority = -1;
    level = await TiledComponent.load('Level1.tmx', Vector2.all(16));
    add(level);
    super.onLoad();
  }
}
