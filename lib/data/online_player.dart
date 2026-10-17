import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The player's online identity for the global leaderboard: their player ID
// and the name they chose.
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

  // Saves a new name (removing spaces at the start and end). Only call this
  // with a name that nameProblem() accepts.
  static Future<void> saveName(String newName) async {
    _name = newName.trim();
    await _storage.setString(_nameStorageKey, _name!);
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
}
