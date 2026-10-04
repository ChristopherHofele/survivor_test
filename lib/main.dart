import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:survivor_test/overlays/game_over.dart';
import 'package:survivor_test/overlays/start_screen.dart';
import 'package:survivor_test/survivor_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  await SoLoud.instance.init(
    sampleRate: 44100, // Audio quality
    bufferSize: 2048, // Buffer size affects latency
    channels: Channels.stereo,
  );

  runApp(const GameApp());
}

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  // Giving the GameWidget a new key makes Flutter build a brand-new game
  Key _gameKey = UniqueKey();

  void _restart() {
    setState(() {
      _gameKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<SurvivorTest>.controlled(
      key: _gameKey,
      gameFactory: () => SurvivorTest(onReturnToMenu: _restart),
      overlayBuilderMap: {
        'StartScreen': (_, game) => StartScreen(game: game),
        'GameOver': (_, game) => GameOver(game: game),
      },
      initialActiveOverlays: const ['StartScreen'],
    );
  }
}
