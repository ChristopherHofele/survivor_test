import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:survivor_test/data/blocked_names.dart';
import 'package:survivor_test/data/personal_bests.dart';

// The player's online identity for the global leaderboard: their player ID,
// the name they chose, and sending their best score.
// Players never log in themselves: the first time the game runs, Firebase
// creates an anonymous account and remembers it on the device. Every later
// start uses that same account again, so each phone keeps one player ID
// (until the game is uninstalled or its data is cleared).
class OnlinePlayer {
  // ---- Name rules (shown on the global leaderboard) ----
  static const int minNameLength = 3;
  static const int maxNameLength = 12;
  // Letters (also ä, é, ...), digits, spaces, - and _
  static final _allowedNameCharacters = RegExp(
    r'^[\p{L}\p{N} _-]+$',
    unicode: true,
  );

  static final _auth = FirebaseAuth.instance;
  static final _storage = SharedPreferencesAsync();
  static const String _nameStorageKey = 'player_name';

  // The player's ID, or null while not signed in (e.g. no internet so far)
  static String? get id => _auth.currentUser?.uid;

  // The player's name, or null if they haven't chosen one yet.
  // Call loadName() once when the app starts before using it.
  static String? get name => _name;
  static String? _name;

  static Future<void> loadName() async {
    _name = await _storage.getString(_nameStorageKey);
  }

  // Saves a new name (removing spaces at the start and end) and also changes
  // it on the global leaderboard. Only call this with a name that
  // nameProblem() accepts. An unchanged name sends nothing.
  static Future<void> saveName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed == _name) return;
    _name = trimmed;
    await _storage.setString(_nameStorageKey, trimmed);
    unawaited(_renameLeaderboardEntry(trimmed));
  }

  // Forgets the saved name (used by a testing switch)
  static Future<void> clearName() async {
    _name = null;
    await _storage.remove(_nameStorageKey);
  }

  // What's wrong with a name the player typed, as a hint to show them,
  // or null if the name is fine
  static String? nameProblem(String typedName) {
    final trimmed = typedName.trim();
    // runes counts each letter once, even unusual ones
    final length = trimmed.runes.length;
    if (length < minNameLength) {
      return 'At least $minNameLength characters';
    }
    if (length > maxNameLength) {
      return 'At most $maxNameLength characters';
    }
    if (!_allowedNameCharacters.hasMatch(trimmed)) {
      return 'Only letters, numbers, spaces, - and _';
    }
    if (BlockedNames.contains(trimmed)) {
      return "This name isn't allowed";
    }
    return null;
  }

  // A sign-in that is still running, so a second call waits for it instead
  // of creating a second account
  static Future<bool>? _runningSignIn;

  // Called once when the game starts. It runs in the background, so the game
  // doesn't wait for it, and it never crashes the game without internet.
  static Future<void> signIn() async {
    if (await ensureSignedIn()) {
      debugPrint('Signed in to Firebase as $id');
    }
  }

  // Makes sure the player is signed in, trying again if an earlier attempt
  // failed. Returns true if the player is signed in.
  // Use this before anything that needs the player ID.
  static Future<bool> ensureSignedIn() {
    return _runningSignIn ??= _signInIfNeeded().whenComplete(() {
      _runningSignIn = null;
    });
  }

  static Future<bool> _signInIfNeeded() async {
    try {
      // When the app starts, Firebase needs a moment to load the remembered
      // account from the device, so wait for that before checking
      final rememberedUser = await _auth.authStateChanges().first;
      if (rememberedUser != null) {
        return true;
      }
      await _auth.signInAnonymously();
      return true;
    } catch (error) {
      debugPrint('Firebase sign-in failed: $error');
      return false;
    }
  }

  // ---- Global leaderboard ----
  // The Firestore list with one entry per player, named after their ID
  static const String leaderboardCollection = 'leaderboard';
  static CollectionReference<Map<String, dynamic>> get _leaderboard =>
      FirebaseFirestore.instance.collection(leaderboardCollection);

  // Sends the player's best score to the global leaderboard if it beats
  // what's there (or if they have no entry yet). Pass the best entry of
  // the personal bests, not just this run: that way a record from a time
  // when sending wasn't possible still gets sent later.
  // Never throws, so it can safely run in the background.
  static Future<void> submitBest(ScoreEntry best) async {
    try {
      final playerName = _name;
      if (playerName == null || !await ensureSignedIn()) return;
      final entry = _leaderboard.doc(id);

      // Look at the current entry first. Without internet, Firestore uses
      // the last known copy on the device, or fails if it has none (then
      // we send anyway).
      int? onlineScore;
      try {
        final snapshot = await entry.get();
        onlineScore = snapshot.data()?['score'] as int?;
      } catch (_) {
        onlineScore = null;
      }
      if (onlineScore != null && best.score <= onlineScore) return;

      // Not awaited on purpose: without internet, Firestore keeps the write
      // on the device and sends it as soon as there's a connection again,
      // even after the game was closed in between
      unawaited(
        entry
            .set({
              'name': playerName,
              'score': best.score,
              'character': best.character.name,
              'date': Timestamp.fromDate(best.date),
              // The server fills in its own time (the rules use it later)
              'updatedAt': FieldValue.serverTimestamp(),
            })
            .then((_) => debugPrint('Score ${best.score} sent to leaderboard'))
            .catchError((Object error) {
              debugPrint('Sending score failed: $error');
            }),
      );
    } catch (error) {
      debugPrint('Sending score failed: $error');
    }
  }

  // Changes the name on the player's leaderboard entry, if they have one
  static Future<void> _renameLeaderboardEntry(String newName) async {
    try {
      if (!await ensureSignedIn()) return;
      // update() only changes an entry that already exists. Without an
      // entry it fails, which is fine: the next score sent has the new name.
      await _leaderboard.doc(id).update({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Leaderboard name changed to $newName');
    } on FirebaseException catch (error) {
      if (error.code == 'not-found') return;
      debugPrint('Changing leaderboard name failed: $error');
    } catch (error) {
      debugPrint('Changing leaderboard name failed: $error');
    }
  }
}
