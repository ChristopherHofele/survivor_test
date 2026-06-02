import 'package:flutter/material.dart';
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
              const SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }
}
