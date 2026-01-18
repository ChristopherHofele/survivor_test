import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:survivor_test/overlays/game_over.dart';
import 'package:survivor_test/overlays/start_screen.dart';
import 'package:survivor_test/survivor_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  //SurvivorTest game = SurvivorTest();
  runApp(
    GameWidget<SurvivorTest>.controlled(
      gameFactory: SurvivorTest.new,
      overlayBuilderMap: {
        'StartScreen': (_, game) => StartScreen(game: game),
        'GameOver': (_, game) => GameOver(game: game),
      },
      initialActiveOverlays: const ['StartScreen'],
    ),
  );
}
