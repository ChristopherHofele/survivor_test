import 'package:flutter/material.dart';

import 'package:survivor_test/data/leaderboard.dart';
import 'package:survivor_test/data/online_player.dart';
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

  // How long to wait for this run's score to be handed to Firestore
  // before loading the board anyway
  static const Duration submissionWaitLimit = Duration(seconds: 5);

  // Started once when the screen opens (not on every redraw), and again
  // with "Try again"
  late Future<LeaderboardResult> _result = _loadAfterSubmission();

  // What happened to this run's score (null from the start screen, or if
  // sending took too long)
  SubmitResult? _submitResult;

  Future<LeaderboardResult> _loadAfterSubmission() async {
    // After a run: wait until this run's score has been handed to
    // Firestore, so a new record already shows
    final submission = game.leaderboardSubmission;
    if (submission != null) {
      _submitResult = await submission.timeout(
        submissionWaitLimit,
        onTimeout: () => SubmitResult.couldNotSend,
      );
    }
    return Leaderboard.load();
  }

  void _tryAgain() {
    // setState redraws the screen, which shows "Loading..." again
    setState(() {
      _result = Leaderboard.load();
    });
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
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;
              final result = isLoading ? null : snapshot.data;
              final failed = !isLoading && snapshot.hasError;
              final message = widget.fromStartScreen || isLoading
                  ? null
                  : _message(result, snapshot.error);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Global Leaderboard',
                    style: TextStyle(color: whiteTextColor, fontSize: 28),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GlobalLeaderboard.highlightColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Flexible(
                    child: isLoading
                        ? const Text(
                            'Loading...',
                            style: TextStyle(color: whiteTextColor),
                          )
                        : failed
                        ? _errorText(snapshot.error)
                        : _board(result!),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (failed) ...[
                        _button('Try again', _tryAgain),
                        const SizedBox(width: 16),
                      ],
                      widget.fromStartScreen
                          ? _button('Back', _backToStartScreen)
                          : _button('Main Menu', game.onReturnToMenu),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Why the board couldn't be shown
  Widget _errorText(Object? error) {
    final String text;
    if (error is NoConnection) {
      text = 'No connection – leaderboard unavailable';
    } else {
      debugPrint('Loading the leaderboard failed: $error');
      text = "Couldn't load the leaderboard. Please try again later.";
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: whiteTextColor, fontSize: 18),
    );
  }

  Widget _board(LeaderboardResult result) {
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

  // The line under the title after a run: the player's place, or what
  // happens to their score while offline (null = no line)
  String? _message(LeaderboardResult? result, Object? error) {
    if (result != null) {
      final me = result.me;
      return me == null
          ? 'Not on the board yet'
          : "You're #${me.rank} of ${result.playerCount} players!";
    }
    if (error is NoConnection) {
      switch (_submitResult) {
        case SubmitResult.sent:
          return "Your new best will be sent once you're online";
        case SubmitResult.couldNotSend:
          return 'Your best will be sent after your next run with internet';
        case SubmitResult.notNeeded:
        case null:
          return null;
      }
    }
    return null;
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

  void _backToStartScreen() {
    game.overlays.remove(GlobalLeaderboard.overlayFromStartScreen);
    game.overlays.add('StartScreen');
  }

  Widget _button(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: whiteTextColor),
        child: Text(
          label,
          style: const TextStyle(fontSize: 22.0, color: blackTextColor),
        ),
      ),
    );
  }
}
