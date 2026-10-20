import 'package:flutter/material.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/data/unlocks.dart';
import 'package:survivor_test/overlays/menu_colors.dart';
import 'package:survivor_test/survivor_test.dart';

// Opened with "Play" on the start screen: pick a character, then Start.
// Locked characters are greyed out with what unlocks them underneath.
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

  bool _isUnlocked(CharacterChoice character) =>
      SurvivorTest.debugUnlockAllCharacters || Unlocks.isUnlocked(character);

  @override
  void initState() {
    super.initState();
    // Start with the character played last time, or the starting character
    if (game.selectedCharacter == CharacterChoice.Undecided) {
      game.selectedCharacter =
          Unlocks.lastCharacter ?? Unlocks.startingCharacter;
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
                'Character Selection',
                style: TextStyle(color: whiteTextColor, fontSize: 30),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                width: 900,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          Unlocks.saveLastCharacter(game.selectedCharacter);
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

  // A character's button, with what unlocks it underneath while locked
  Widget _characterButton(String label, CharacterChoice choice) {
    final isSelected = game.selectedCharacter == choice;
    final isUnlocked = _isUnlocked(choice);
    final milestone = Unlocks.milestones[choice];
    return Column(
      children: [
        ElevatedButton.icon(
          // A null onPressed greys the button out: locked characters can't
          // be chosen
          onPressed: isUnlocked
              ? () {
                  // setState redraws the screen so the highlight updates
                  setState(() {
                    game.selectedCharacter = choice;
                  });
                }
              : null,
          icon: isUnlocked
              ? null
              : Icon(Icons.lock, size: 18, color: Colors.grey.shade400),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? CharacterSelectScreen.selectedColor
                : whiteTextColor,
            disabledBackgroundColor: Colors.grey.shade700,
          ),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 20.0,
              color: isUnlocked ? blackTextColor : Colors.grey.shade400,
            ),
          ),
        ),
        if (!isUnlocked && milestone != null) ...[
          const SizedBox(height: 6),
          Text(
            milestone.hint(Unlocks.totalKills),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ],
    );
  }
}
