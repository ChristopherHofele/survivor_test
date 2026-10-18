import 'package:flutter/material.dart';

import 'package:survivor_test/data/leaderboard.dart';
import 'package:survivor_test/overlays/menu_colors.dart';
import 'package:survivor_test/survivor_test.dart';

// The global leaderboard: the best players worldwide, with the player's own
// entry highlighted. Shown after the personal bests screen (with the
// player's place and a "Main Menu" button) and from the start screen
// (with a "Back" button).
class GlobalLeaderboard extends StatefulWidget {
  final SurvivorTest game;
  // True when opened from the start screen
  final bool fromStartScreen;
  const GlobalLeaderboard({
    super.key,
    required this.game,
    this.fromStartScreen = false,
  });

  // The names of this screen in the overlay list in main.dart
  static const String overlayAfterGame = 'GlobalLeaderboard';
  static const String overlayFromStartScreen = 'GlobalLeaderboardFromMenu';

  // The colour the player's own entry is highlighted in (same as on the
  // personal bests screen)
  static const highlightColor = Colors.amber;

  @override
  State<GlobalLeaderboard> createState() => _GlobalLeaderboardState();
}

class _GlobalLeaderboardState extends State<GlobalLeaderboard> {
  SurvivorTest get game => widget.game;

  // Started once when the screen opens (not on every redraw)
  late final Future<LeaderboardResult> _result = _load();

  Future<LeaderboardResult> _load() async {
    // After a run: wait until this run's score has been handed to Firestore
    await game.leaderboardSubmission;
    return Leaderboard.load();
  }

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
          // Shows "Loading..." until the board has arrived
          child: FutureBuilder<LeaderboardResult>(
            future: _result,
            builder: (context, snapshot) {
              final result = snapshot.data;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Global Leaderboard',
                    style: TextStyle(color: whiteTextColor, fontSize: 28),
                  ),
                  if (result != null && !widget.fromStartScreen) ...[
                    const SizedBox(height: 4),
                    _resultMessage(result),
                  ],
                  const SizedBox(height: 8),
                  Flexible(child: _body(snapshot)),
                  const SizedBox(height: 10),
                  _button(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(AsyncSnapshot<LeaderboardResult> snapshot) {
    if (snapshot.hasError) {
      // TODO: a clearer offline message comes in step 7
      debugPrint('Loading the leaderboard failed: ${snapshot.error}');
      return const Text(
        "Couldn't load the leaderboard",
        style: TextStyle(color: whiteTextColor),
      );
    }
    final result = snapshot.data;
    if (result == null) {
      return const Text('Loading...', style: TextStyle(color: whiteTextColor));
    }
    if (result.top.isEmpty) {
      return const Text(
        'No scores yet',
        style: TextStyle(color: whiteTextColor),
      );
    }
    final me = result.me;
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final row in result.top) _row(row),
          // The player's own line below the list, if they're further down
          if (me != null && !result.meIsInTop) ...[
            const Text('···', style: TextStyle(color: whiteTextColor)),
            _row(me),
          ],
        ],
      ),
    );
  }

  // The line under the title: the player's place
  Widget _resultMessage(LeaderboardResult result) {
    final me = result.me;
    final message = me == null
        ? 'Not on the board yet'
        : "You're #${me.rank} of ${result.playerCount} players!";
    return Text(
      message,
      style: const TextStyle(
        color: GlobalLeaderboard.highlightColor,
        fontSize: 16,
      ),
    );
  }

  // One line: place, name, character, score
  Widget _row(LeaderboardRow row) {
    final style = TextStyle(
      color: row.isMe ? GlobalLeaderboard.highlightColor : whiteTextColor,
      fontSize: 16,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('${row.rank}.', style: style)),
          Expanded(child: Text(row.name, style: style)),
          SizedBox(width: 110, child: Text(row.character, style: style)),
          SizedBox(
            width: 80,
            child: Text(
              '${row.score}',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // "Main Menu" after a run, "Back" from the start screen
  Widget _button() {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: widget.fromStartScreen
            ? () {
                game.overlays.remove(GlobalLeaderboard.overlayFromStartScreen);
                game.overlays.add('StartScreen');
              }
            : game.onReturnToMenu,
        style: ElevatedButton.styleFrom(backgroundColor: whiteTextColor),
        child: Text(
          widget.fromStartScreen ? 'Back' : 'Main Menu',
          style: const TextStyle(fontSize: 22.0, color: blackTextColor),
        ),
      ),
    );
  }
}
