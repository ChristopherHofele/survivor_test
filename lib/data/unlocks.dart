import 'package:shared_preferences/shared_preferences.dart';

import 'package:survivor_test/actors/player.dart';

// What the milestones look at from the current run
class RunProgress {
  final int bossesDefeated;
  final int enemiesKilled;
  // True once the same kind of fruit was eaten twice within one stretch of
  // the run (before the first boss, between two bosses, or after the last)
  final bool ateSameFruitTwice;
  const RunProgress({
    required this.bossesDefeated,
    required this.enemiesKilled,
    required this.ateSameFruitTwice,
  });
}

// How one character is unlocked
class Milestone {
  // Shown under the locked character, e.g. "Defeat the boss"
  final String Function(int totalKills) hint;
  // True when the milestone is reached. totalKills already includes this
  // run's kills.
  final bool Function(RunProgress run, int totalKills) isReached;
  const Milestone({required this.hint, required this.isReached});
}

// Which characters the player has unlocked, saved on the device (deleted
// when the game is uninstalled, like the personal bests)
class Unlocks {
  // ---- Tuning ----
  static const CharacterChoice startingCharacter = CharacterChoice.FireGuy;
  static const int bossesForMeleeLad = 1;
  static const int totalKillsForDashMan = 500;

  // ---- The milestones (a new character only needs a new line here) ----
  static final Map<CharacterChoice, Milestone> milestones = {
    CharacterChoice.MeleeLad: Milestone(
      hint: (_) => 'Defeat the boss',
      isReached: (run, _) => run.bossesDefeated >= bossesForMeleeLad,
    ),
    CharacterChoice.DashMan: Milestone(
      hint: (totalKills) =>
          'Defeat $totalKillsForDashMan enemies '
          '(${totalKills.clamp(0, totalKillsForDashMan)}/$totalKillsForDashMan)',
      isReached: (_, totalKills) => totalKills >= totalKillsForDashMan,
    ),
    // A secret achievement: the hint doesn't give it away
    CharacterChoice.MineFellow: Milestone(
      hint: (_) => '???',
      isReached: (run, _) => run.ateSameFruitTwice,
    ),
  };

  static final _storage = SharedPreferencesAsync();
  static const String _unlockedKey = 'unlocked_characters';
  static const String _totalKillsKey = 'total_kills';
  static const String _lastCharacterKey = 'last_character';

  static final Set<CharacterChoice> _unlocked = {};
  static int _totalKills = 0;
  static CharacterChoice? _lastCharacter;

  // Enemies defeated in all saved runs together (not the current one)
  static int get totalKills => _totalKills;

  // The character played last time, if it's still unlocked
  static CharacterChoice? get lastCharacter {
    final last = _lastCharacter;
    return last != null && isUnlocked(last) ? last : null;
  }

  static bool isUnlocked(CharacterChoice character) =>
      character == startingCharacter || _unlocked.contains(character);

  // Call once when the app starts, before the menus use any of this
  static Future<void> load() async {
    final saved = await _storage.getStringList(_unlockedKey) ?? [];
    _unlocked
      ..clear()
      ..addAll(_charactersFromNames(saved));
    _totalKills = await _storage.getInt(_totalKillsKey) ?? 0;
    final last = await _storage.getString(_lastCharacterKey);
    _lastCharacter = _charactersFromNames([if (last != null) last]).firstOrNull;
  }

  // Forgets all unlocks and counters (used by a testing switch)
  static Future<void> reset() async {
    _unlocked.clear();
    _totalKills = 0;
    _lastCharacter = null;
    await _storage.remove(_unlockedKey);
    await _storage.remove(_totalKillsKey);
    await _storage.remove(_lastCharacterKey);
  }

  static Future<void> saveLastCharacter(CharacterChoice character) async {
    _lastCharacter = character;
    await _storage.setString(_lastCharacterKey, character.name);
  }

  // The characters whose milestone is reached right now but which aren't
  // unlocked yet (and weren't announced in this run already). Can be called
  // at any time during a run; it answers instantly and changes nothing.
  static List<CharacterChoice> newlyReached(
    RunProgress run, {
    Set<CharacterChoice> alreadyAnnounced = const {},
  }) {
    final totalKillsNow = _totalKills + run.enemiesKilled;
    return [
      for (final entry in milestones.entries)
        if (!isUnlocked(entry.key) &&
            !alreadyAnnounced.contains(entry.key) &&
            entry.value.isReached(run, totalKillsNow))
          entry.key,
    ];
  }

  // Unlocks characters for good and saves them
  static Future<void> unlock(List<CharacterChoice> characters) async {
    if (characters.isEmpty) return;
    _unlocked.addAll(characters);
    await _storage.setStringList(
      _unlockedKey,
      _unlocked.map((character) => character.name).toList(),
    );
  }

  // At game over: checks the milestones one last time and adds this run's
  // kills to the total. With save: false (test runs) nothing is saved.
  // Returns the characters unlocked by this last check.
  static Future<List<CharacterChoice>> finishRun(
    RunProgress run, {
    required bool save,
    Set<CharacterChoice> alreadyAnnounced = const {},
  }) async {
    final newlyUnlocked = newlyReached(
      run,
      alreadyAnnounced: alreadyAnnounced,
    );
    if (save) {
      await unlock(newlyUnlocked);
      _totalKills += run.enemiesKilled;
      await _storage.setInt(_totalKillsKey, _totalKills);
    }
    return newlyUnlocked;
  }

  // Saved names like "DashMan" back to characters (unknown names skipped)
  static Iterable<CharacterChoice> _charactersFromNames(List<String> names) =>
      CharacterChoice.values.where((choice) => names.contains(choice.name));
}
