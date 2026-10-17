import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// The player's online identity for the global leaderboard.
// Players never log in themselves: the first time the game runs, Firebase
// creates an anonymous account and remembers it on the device. Every later
// start uses that same account again, so each phone keeps one player ID
// (until the game is uninstalled or its data is cleared).
class OnlinePlayer {
  static final _auth = FirebaseAuth.instance;

  // The player's ID, or null while not signed in (e.g. no internet so far)
  static String? get id => _auth.currentUser?.uid;

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
