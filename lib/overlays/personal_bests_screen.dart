import 'package:flutter/material.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/data/personal_bests.dart';
import 'package:survivor_test/overlays/menu_colors.dart';
import 'package:survivor_test/survivor_test.dart';

// Shown after the game over screen: the player's best scores with the date
// and character, with this run highlighted if it made the list.
class PersonalBestsScreen extends StatelessWidget {
  final SurvivorTest game;
  const PersonalBestsScreen({super.key, required this.game});

  // The colour this run's row is highlighted in (same as the selected
  // character on the start screen)
  static const highlightColor = Colors.amber;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          width: 480,
          // Never taller than the screen: the list scrolls if needed
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.95,
          ),
          decoration: const BoxDecoration(
            color: blackTextColor,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          // Saving the score may still be running; this waits for it
          child: FutureBuilder<PersonalBestsResult>(
            future: game.personalBestsResult,
            builder: (context, snapshot) {
              final result = snapshot.data;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Personal Bests',
                    style: TextStyle(color: whiteTextColor, fontSize: 28),
                  ),
                  const SizedBox(height: 4),
                  if (result != null) _resultMessage(result),
                  const SizedBox(height: 8),
                  Flexible(
                    child: result == null
                        ? const Text(
                            'Loading...',
                            style: TextStyle(color: whiteTextColor),
                          )
                        : _scoreList(result),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        game.overlays.remove('PersonalBests');
                        game.overlays.add('GlobalLeaderboard');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteTextColor,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 22.0, color: blackTextColor),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // The line under the title: new record, made the list, or didn't
  Widget _resultMessage(PersonalBestsResult result) {
    final String message;
    if (result.place == 0) {
      message = 'New personal best!';
    } else if (result.place != null) {
      message = 'This run is #${result.place! + 1} on your list';
    } else {
      message =
          'Your score ${game.finalScore} is not in your '
          'top ${PersonalBests.maxEntries}';
    }
    return Text(
      message,
      style: const TextStyle(color: highlightColor, fontSize: 16),
    );
  }

  Widget _scoreList(PersonalBestsResult result) {
    if (result.entries.isEmpty) {
      return const Text(
        'No scores yet',
        style: TextStyle(color: whiteTextColor),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          for (int i = 0; i < result.entries.length; i++)
            _scoreRow(i, result.entries[i], isThisRun: i == result.place),
        ],
      ),
    );
  }

  // One row: place, score, character, date
  Widget _scoreRow(int index, ScoreEntry entry, {required bool isThisRun}) {
    final style = TextStyle(
      color: isThisRun ? highlightColor : whiteTextColor,
      fontSize: 16,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('${index + 1}.', style: style)),
          SizedBox(
            width: 80,
            child: Text(
              '${entry.score}',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(characterNames[entry.character]!, style: style),
          ),
          Text(_formatDate(entry.date), style: style),
        ],
      ),
    );
  }

  // e.g. 12/10/2026 (day/month/year)
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
