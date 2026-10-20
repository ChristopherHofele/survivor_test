import 'dart:async';

import 'package:flutter/material.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/overlays/menu_colors.dart';
import 'package:survivor_test/survivor_test.dart';

// Shows the run's stats one after another with the points each one gives,
// then the final score, any characters unlocked in this run, then a button
// that leads to the leaderboard.
class GameOver extends StatefulWidget {
  final SurvivorTest game;
  const GameOver({super.key, required this.game});

  @override
  State<GameOver> createState() => _GameOverState();
}

class _GameOverState extends State<GameOver> {
  // Time between one line appearing and the next
  static const Duration revealInterval = Duration(milliseconds: 600);
  // The colour of the "New character unlocked" line
  static const unlockColor = Colors.amber;

  // How much is visible so far: 1-4 = stat lines, 5 = score,
  // 6 = unlocked characters (only if there are any), then the button
  int _revealed = 0;
  static const int _scoreStep = 5;
  static const int _unlockStep = 6;
  int get _buttonStep => _unlocked.isEmpty ? _unlockStep : _unlockStep + 1;
  late final Timer _revealTimer;

  // Characters unlocked in this run (checking takes a moment)
  List<CharacterChoice> _unlocked = [];

  SurvivorTest get game => widget.game;

  @override
  void initState() {
    super.initState();
    game.newlyUnlocked?.then((unlocked) {
      if (mounted) setState(() => _unlocked = unlocked);
    });
    _revealTimer = Timer.periodic(revealInterval, (timer) {
      setState(() => _revealed += 1);
      if (_revealed >= _buttonStep) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _revealTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          width: 440,
          decoration: const BoxDecoration(
            color: blackTextColor,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Game Over',
                style: TextStyle(color: whiteTextColor, fontSize: 30),
              ),
              const SizedBox(height: 12),
              _statLine(
                1,
                'Enemies killed',
                '${game.enemiesKilled}',
                game.killPoints,
              ),
              _statLine(
                2,
                'Bosses defeated',
                '${game.bossesDefeated}',
                game.bossPoints,
              ),
              _statLine(
                3,
                'Time survived',
                _formatTime(game.timeSurvived),
                game.timePoints,
              ),
              _statLine(4, 'Times hit', '${game.timesHit}', -game.hitPoints),
              _appear(
                _scoreStep,
                Column(
                  children: [
                    const Divider(color: whiteTextColor),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Score',
                            style: TextStyle(
                              color: whiteTextColor,
                              fontSize: 26,
                            ),
                          ),
                        ),
                        Text(
                          '${game.finalScore}',
                          style: const TextStyle(
                            color: whiteTextColor,
                            fontSize: 26,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_unlocked.isNotEmpty)
                _appear(_unlockStep, _unlockLines()),
              const SizedBox(height: 12),
              _appear(
                _buttonStep,
                SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      game.overlays.remove('GameOver');
                      game.overlays.add('PersonalBests');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: whiteTextColor,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 24.0, color: blackTextColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // One line for all new characters, e.g. "New character unlocked: Melee
  // Lad!" or "New characters unlocked: Melee Lad and Dash Man!"
  Widget _unlockLines() {
    final names = [
      for (final character in _unlocked) characterNames[character]!,
    ];
    final list = names.length == 1
        ? names.first
        : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
    final heading = names.length == 1
        ? 'New character unlocked'
        : 'New characters unlocked';
    // Test runs don't save unlocks, so say so
    final note = SurvivorTest.isTestRun ? ' (test run – not saved)' : '';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '$heading: $list!$note',
        textAlign: TextAlign.center,
        style: const TextStyle(color: unlockColor, fontSize: 18),
      ),
    );
  }

  // One stat: name, value and the points it gives (or costs)
  Widget _statLine(int step, String name, String value, int points) {
    const style = TextStyle(color: whiteTextColor, fontSize: 18);
    final pointsText = points < 0 ? '$points' : '+$points';
    return _appear(
      step,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(name, style: style)),
            SizedBox(
              width: 80,
              child: Text(value, style: style, textAlign: TextAlign.right),
            ),
            SizedBox(
              width: 90,
              child: Text(pointsText, style: style, textAlign: TextAlign.right),
            ),
          ],
        ),
      ),
    );
  }

  // Fades the child in once the reveal has reached its step. It takes up its
  // space from the start, so the box doesn't change size while revealing.
  Widget _appear(int step, Widget child) {
    final visible = _revealed >= step;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: child,
      ),
    );
  }

  // Turns seconds into minutes:seconds, e.g. 125.7 -> "2:05"
  String _formatTime(double seconds) {
    final totalSeconds = seconds.floor();
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
