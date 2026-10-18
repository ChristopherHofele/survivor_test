import 'package:flutter/material.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/overlays/menu_colors.dart';
import 'package:survivor_test/survivor_test.dart';

// Opened with "Play" on the start screen: pick a character, then Start.
class CharacterSelectScreen extends StatefulWidget {
  final SurvivorTest game;
  const CharacterSelectScreen({super.key, required this.game});

  // The name of this screen in the overlay list in main.dart
  static const String overlayName = 'CharacterSelect';

  // The colour of the chosen character's button
  static const selectedColor = Colors.amber;

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  SurvivorTest get game => widget.game;

  bool get _characterChosen =>
      game.selectedCharacter != CharacterChoice.Undecided;

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
                'Character Selection',
                style: TextStyle(color: whiteTextColor, fontSize: 30),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 75,
                width: 900,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _characterButton('Fire Guy', CharacterChoice.FireGuy),
                    _characterButton('Melee Lad', CharacterChoice.MeleeLad),
                    _characterButton('Dash Man', CharacterChoice.DashMan),
                    _characterButton('Mine Fellow', CharacterChoice.MineFellow),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 75,
                child: ElevatedButton(
                  // A null onPressed disables the button until a character
                  // has been chosen
                  onPressed: _characterChosen
                      ? () {
                          game.startGame = true;
                          game.overlays.remove(CharacterSelectScreen.overlayName);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whiteTextColor,
                    disabledBackgroundColor: Colors.grey.shade700,
                  ),
                  child: const Text(
                    'Start',
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
                    game.overlays.remove(CharacterSelectScreen.overlayName);
                    game.overlays.add('StartScreen');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whiteTextColor,
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontSize: 24.0, color: blackTextColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _characterButton(String label, CharacterChoice choice) {
    final isSelected = game.selectedCharacter == choice;
    return ElevatedButton(
      onPressed: () {
        // setState redraws the screen so the highlight and Start button update
        setState(() {
          game.selectedCharacter = choice;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? CharacterSelectScreen.selectedColor
            : whiteTextColor,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20.0, color: blackTextColor),
      ),
    );
  }
}
