import 'package:flutter/material.dart';

import 'package:survivor_test/survivor_test.dart';

class GameOver extends StatelessWidget {
  final SurvivorTest game;
  const GameOver({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    const blackTextColor = Color.fromRGBO(0, 0, 0, 1.0);
    const whiteTextColor = Color.fromRGBO(255, 255, 255, 1.0);
    const statStyle = TextStyle(color: whiteTextColor, fontSize: 20);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          height: 320,
          width: 400,
          decoration: const BoxDecoration(
            color: blackTextColor,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Game Over',
                style: TextStyle(color: whiteTextColor, fontSize: 30),
              ),
              const SizedBox(height: 20),
              Text('Enemies killed: ${game.enemiesKilled}', style: statStyle),
              const SizedBox(height: 8),
              Text('Bosses defeated: ${game.bossesDefeated}', style: statStyle),
              const SizedBox(height: 8),
              Text(
                'Time survived: ${_formatTime(game.timeSurvived)}',
                style: statStyle,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 200,
                height: 75,
                child: ElevatedButton(
                  onPressed: () {
                    game.onReturnToMenu();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whiteTextColor,
                  ),
                  child: const Text(
                    'Main Menu',
                    style: TextStyle(fontSize: 28.0, color: blackTextColor),
                  ),
                ),
              ),
            ],
          ),
        ),
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
