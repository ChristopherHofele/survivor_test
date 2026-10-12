import 'package:flutter/material.dart';

import 'package:survivor_test/overlays/menu_colors.dart';
import 'package:survivor_test/survivor_test.dart';

// Shown after the game over screen.
// PLACEHOLDER: the real leaderboard comes later; for now it shows the score
// and the button back to the main menu.
class Leaderboard extends StatelessWidget {
  final SurvivorTest game;
  const Leaderboard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          width: 440,
          decoration: const BoxDecoration(
            color: blackTextColor,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Leaderboard',
                style: TextStyle(color: whiteTextColor, fontSize: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Your score: ${game.finalScore}',
                style: const TextStyle(color: whiteTextColor, fontSize: 22),
              ),
              const SizedBox(height: 8),
              const Text(
                'Leaderboard coming soon',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 56,
                child: ElevatedButton(
                  onPressed: game.onReturnToMenu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whiteTextColor,
                  ),
                  child: const Text(
                    'Main Menu',
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
}
