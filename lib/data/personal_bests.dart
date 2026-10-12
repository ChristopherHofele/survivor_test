import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:survivor_test/actors/player.dart';

// One finished run on the personal best list
class ScoreEntry {
  final int score;
  final DateTime date;
  final CharacterChoice character;
  const ScoreEntry({
    required this.score,
    required this.date,
    required this.character,
  });

  // The device can only store simple values like text, so each entry is
  // saved as a JSON text, e.g.
  // {"score":5150,"date":"2026-10-12T14:03:00.000","character":"FireGuy"}
  Map<String, dynamic> toJson() => {
    'score': score,
    'date': date.toIso8601String(),
    'character': character.name,
  };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
    score: json['score'] as int,
    date: DateTime.parse(json['date'] as String),
    character: CharacterChoice.values.byName(json['character'] as String),
  );
}

// The result of adding a score: the updated list and where the new score
// landed (0 = first place), or null if it didn't make the list
class PersonalBestsResult {
  final List<ScoreEntry> entries;
  final int? place;
  const PersonalBestsResult({required this.entries, required this.place});
}

// The player's best scores, saved on the device (they stay after closing
// the game, but are deleted when the game is uninstalled)
class PersonalBests {
  // How many scores the list keeps
  static const int maxEntries = 10;
  static const String _storageKey = 'personal_bests';
  static final _storage = SharedPreferencesAsync();

  // The saved scores, best first (empty if nothing is saved yet)
  static Future<List<ScoreEntry>> load() async {
    final savedTexts = await _storage.getStringList(_storageKey) ?? [];
    final entries = <ScoreEntry>[];
    for (final text in savedTexts) {
      try {
        entries.add(ScoreEntry.fromJson(jsonDecode(text)));
      } catch (_) {
        // A broken entry is skipped instead of breaking the whole list
      }
    }
    _sortBestFirst(entries);
    return entries;
  }

  // Adds a score, keeps only the best ones and saves the list
  static Future<PersonalBestsResult> add(ScoreEntry newEntry) async {
    final entries = await load();
    entries.add(newEntry);
    _sortBestFirst(entries);
    final kept = entries.take(maxEntries).toList();
    await _storage.setStringList(
      _storageKey,
      kept.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
    final place = kept.indexOf(newEntry);
    return PersonalBestsResult(
      entries: kept,
      place: place == -1 ? null : place,
    );
  }

  // Deletes all saved scores (used by a testing switch)
  static Future<void> clear() => _storage.remove(_storageKey);

  static void _sortBestFirst(List<ScoreEntry> entries) {
    entries.sort((a, b) => b.score.compareTo(a.score));
  }
}
