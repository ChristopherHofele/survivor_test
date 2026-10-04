import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:survivor_test/actors/player.dart';

import 'package:survivor_test/survivor_test.dart';

class StartScreen extends StatelessWidget {
  final SurvivorTest game;

  const StartScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    const blackTextColor = Color.fromRGBO(0, 0, 0, 1.0);
    const whiteTextColor = Color.fromRGBO(255, 255, 255, 1.0);

    return Material(
      color: Colors.transparent,
      elevation: 100,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          height: 540,
          width: 900,
          decoration: const BoxDecoration(
            color: blackTextColor,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Survivor Test',
                style: TextStyle(color: whiteTextColor, fontSize: 30),
              ),
              const Text(
                'Character Selection',
                style: TextStyle(color: whiteTextColor, fontSize: 24),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 75,
                width: 900,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        game.selectedCharacter = CharacterChoice.FireGuy;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteTextColor,
                      ),
                      child: const Text(
                        'Fire Guy',
                        style:
                            TextStyle(fontSize: 20.0, color: blackTextColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        game.selectedCharacter = CharacterChoice.MeleeLad;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteTextColor,
                      ),
                      child: const Text(
                        'Melee Lad',
                        style:
                            TextStyle(fontSize: 20.0, color: blackTextColor),
                      ),
                    ),
                                        ElevatedButton(
                      onPressed: () {
                        game.selectedCharacter = CharacterChoice.DashMan;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteTextColor,
                      ),
                      child: const Text(
                        'Dash Man',
                        style:
                            TextStyle(fontSize: 20.0, color: blackTextColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        game.selectedCharacter = CharacterChoice.MineFellow;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteTextColor,
                      ),
                      child: const Text(
                        'Mine Fellow',
                        style:
                            TextStyle(fontSize: 20.0, color: blackTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 200,
                height: 75,
                child: ElevatedButton(
                  onPressed: () {
                    game.startGame = true;
                    game.overlays.remove('StartScreen');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whiteTextColor,
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(fontSize: 40.0, color: blackTextColor),
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

  void _exitGame() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }
}
