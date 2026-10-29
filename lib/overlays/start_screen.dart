import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:survivor_test/data/online_player.dart';
import 'package:survivor_test/overlays/character_select_screen.dart';
import 'package:survivor_test/overlays/global_leaderboard.dart';
import 'package:survivor_test/overlays/menu_colors.dart';
import 'package:survivor_test/overlays/name_dialog.dart';

import 'package:survivor_test/survivor_test.dart';

// The main menu: the player's name, Play (goes to the character selection),
// Leaderboard and Exit
class StartScreen extends StatefulWidget {
  final SurvivorTest game;

  const StartScreen({super.key, required this.game});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  SurvivorTest get game => widget.game;

  @override
  void initState() {
    super.initState();
    // The very first time, ask for a name. Also ask again if the saved name
    // isn't allowed any more (e.g. after a word was added to the blocked
    // names). A window can only open once the screen has been drawn, so
    // wait for the end of the first frame.
    final savedName = OnlinePlayer.name;
    if (savedName == null || OnlinePlayer.nameProblem(savedName) != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _changeName(canCancel: false);
      });
    }
  }

  Future<void> _changeName({required bool canCancel}) async {
    await showNameDialog(context, canCancel: canCancel);
    // Redraw so the new name shows on the screen
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    return Material(
      // Black over the whole screen, so none of the game shows at the edges
      color: blackTextColor,
      // Keeps the buttons away from a camera notch or rounded corners
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Vegetable Survivors',
                style: TextStyle(color: whiteTextColor, fontSize: 30),
              ),
              // Tap to change the leaderboard name
              TextButton.icon(
                onPressed: () => _changeName(canCancel: true),
                icon: const Icon(Icons.edit, color: whiteTextColor, size: 18),
                iconAlignment: IconAlignment.end,
                label: Text(
                  'Player: ${OnlinePlayer.name ?? '-'}',
                  style: const TextStyle(color: whiteTextColor, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 75,
                child: ElevatedButton(
                  onPressed: () {
                    game.overlays.remove('StartScreen');
                    game.overlays.add(CharacterSelectScreen.overlayName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whiteTextColor,
                  ),
                  child: const Text(
                    'Play',
                    style: TextStyle(fontSize: 40.0, color: blackTextColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    game.overlays.remove('StartScreen');
                    game.overlays.add(GlobalLeaderboard.overlayFromStartScreen);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whiteTextColor,
                  ),
                  child: const Text(
                    'Leaderboard',
                    style: TextStyle(fontSize: 24.0, color: blackTextColor),
                  ),
                ),
              ),
              if (_canExit) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _exitGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: whiteTextColor,
                    ),
                    child: const Text(
                      'Exit',
                      style: TextStyle(fontSize: 24.0, color: blackTextColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // iOS doesn't allow apps to close themselves and a web page can't close
  // its browser tab, so the Exit button only exists on Android and desktop.
  bool get _canExit {
    if (kIsWeb) return false;
    return const {
      TargetPlatform.android,
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    }.contains(defaultTargetPlatform);
  }

  // Audio is handled by the lifecycle listener in main.dart: on Android,
  // closing the app hides it, which pauses all sounds, just like the Back
  // button. On desktop, exit() ends the whole program, sound included.
  void _exitGame() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }
}
