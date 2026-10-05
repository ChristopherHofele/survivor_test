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

  // Tells us when the app goes to the background (home/back button)
  // and when it comes back
  late final AppLifecycleListener _lifecycleListener;
  final List<SoundHandle> _pausedSounds = [];

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onHide: _pauseAllSounds,
      onShow: _resumePausedSounds,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _restart() {
    setState(() {
      _gameKey = UniqueKey();
    });
  }

  void _pauseAllSounds() {
    for (final sound in SoLoud.instance.activeSounds) {
      for (final handle in sound.handles) {
        if (!SoLoud.instance.getPause(handle)) {
          SoLoud.instance.setPause(handle, true);
          _pausedSounds.add(handle);
        }
      }
    }
    // Timers like the boss intro can still start new sounds while the app
    // is in the background, so also mute everything
    SoLoud.instance.setGlobalVolume(0);
  }

  void _resumePausedSounds() {
    SoLoud.instance.setGlobalVolume(1);
    for (final handle in _pausedSounds) {
      // Skip sounds that were disposed while the app was hidden
      if (SoLoud.instance.getIsValidVoiceHandle(handle)) {
        SoLoud.instance.setPause(handle, false);
      }
    }
    _pausedSounds.clear();
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
