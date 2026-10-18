import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:survivor_test/actors/player.dart';
import 'package:survivor_test/data/online_player.dart';

// One line on the global leaderboard
class LeaderboardRow {
  // The place, e.g. 3 for "#3". Equal scores share a place.
  final int rank;
  final String name;
  final String character;
  final int score;
  // True for the player's own entry (highlighted on the screen)
  final bool isMe;
  const LeaderboardRow({
    required this.rank,
    required this.name,
    required this.character,
    required this.score,
    required this.isMe,
  });
}

// Everything the leaderboard screen shows
class LeaderboardResult {
  // The best players, best first
  final List<LeaderboardRow> top;
  // The player's own entry (also when it's in the top list), or null if
  // they're not on the board yet
  final LeaderboardRow? me;
  final int playerCount;
  const LeaderboardResult({
    required this.top,
    required this.me,
    required this.playerCount,
  });

  // True if the player's entry is already in the top list
  bool get meIsInTop => top.any((row) => row.isMe);
}

// Thrown by Leaderboard.load() when there's no (fast enough) connection
class NoConnection implements Exception {
  const NoConnection();
  @override
  String toString() => 'No connection';
}

class Leaderboard {
  // How many of the best players are shown
  static const int topCount = 10;
  // How long loading may take before the screen says "No connection"
  static const Duration timeLimit = Duration(seconds: 8);

  static CollectionReference<Map<String, dynamic>> get _entries =>
      FirebaseFirestore.instance.collection(
        OnlinePlayer.leaderboardCollection,
      );

  // Loads the board. Throws NoConnection without internet (or when it
  // takes longer than timeLimit), or another error if something else went
  // wrong; the screen shows a message then.
  static Future<LeaderboardResult> load() async {
    try {
      return await _load().timeout(timeLimit);
    } on TimeoutException {
      throw const NoConnection();
    } on FirebaseException catch (error) {
      // Firestore's names for "can't reach the server"
      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
        throw const NoConnection();
      }
      rethrow;
    }
  }

  static Future<LeaderboardResult> _load() async {
    // Without a player ID the board can't be read. Signing in only fails
    // without internet.
    if (!await OnlinePlayer.ensureSignedIn()) {
      throw const NoConnection();
    }
    final myId = OnlinePlayer.id;

    // 1. The best entries. Firestore sorts them on the server.
    final topSnapshot = await _entries
        .orderBy('score', descending: true)
        .limit(topCount)
        .get();
    // Without internet, Firestore quietly answers with what it has saved on
    // the device, which may be only a few entries (e.g. just the player's
    // own). That would look like a real board, so treat it as offline.
    if (topSnapshot.metadata.isFromCache) {
      throw const NoConnection();
    }
    final topDocs = topSnapshot.docs.toList()
      // Equal scores: whoever got there first comes first
      ..sort((a, b) {
        final byScore = _score(b).compareTo(_score(a));
        if (byScore != 0) return byScore;
        return _date(a).compareTo(_date(b));
      });

    final top = <LeaderboardRow>[];
    for (int i = 0; i < topDocs.length; i++) {
      // Same score as the line above: same place
      final rank = i > 0 && _score(topDocs[i]) == _score(topDocs[i - 1])
          ? top[i - 1].rank
          : i + 1;
      top.add(_row(topDocs[i], rank: rank, myId: myId));
    }

    // 2. + 3. The player's own entry and place, if not in the top list
    LeaderboardRow? me;
    for (final row in top) {
      if (row.isMe) me = row;
    }
    if (me == null && myId != null) {
      final myDoc = await _entries.doc(myId).get();
      if (myDoc.metadata.isFromCache) {
        throw const NoConnection();
      }
      if (myDoc.exists) {
        // Counting doesn't load the entries, so this stays cheap
        final better = await _entries
            .where('score', isGreaterThan: _score(myDoc))
            .count()
            .get();
        me = _row(myDoc, rank: (better.count ?? 0) + 1, myId: myId);
      }
    }

    // 4. How many players are on the board
    final total = await _entries.count().get();

    return LeaderboardResult(
      top: top,
      me: me,
      playerCount: total.count ?? top.length,
    );
  }

  static int _score(DocumentSnapshot<Map<String, dynamic>> doc) =>
      (doc.data()?['score'] as num?)?.toInt() ?? 0;

  static DateTime _date(DocumentSnapshot<Map<String, dynamic>> doc) {
    final date = doc.data()?['date'];
    return date is Timestamp ? date.toDate() : DateTime(2000);
  }

  static LeaderboardRow _row(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required int rank,
    required String? myId,
  }) {
    final data = doc.data() ?? {};
    return LeaderboardRow(
      rank: rank,
      name: data['name'] as String? ?? '?',
      character: _characterName(data['character'] as String?),
      score: _score(doc),
      isMe: doc.id == myId,
    );
  }

  // "FireGuy" -> "Fire Guy" (as on the start screen)
  static String _characterName(String? saved) {
    for (final choice in CharacterChoice.values) {
      if (choice.name == saved) return characterNames[choice] ?? saved!;
    }
    return saved ?? '?';
  }
}
