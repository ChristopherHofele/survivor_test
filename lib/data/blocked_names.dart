// Rude words that may not be used in leaderboard names (English and German).
//
// The same check also runs on Firebase's servers (isBlockedName in
// firestore.rules). After changing anything in this file, update the rules
// with
//     dart run tool/update_blocked_names_rules.dart
// and paste firestore.rules into the Firebase console again.
//
// Before checking, a name is cleaned up so simple tricks don't work:
// capitals become small letters, accents are removed (ä -> a), some digits
// count as letters (0 -> o, 1 -> i, 3 -> e, 4 -> a, 5 -> s, 7 -> t), and a
// letter written several times counts once ("fuuuck" = "fuck").
// So the words below are written in small letters without accents.
// (No imports on purpose, so the update script above can use this file.)
class BlockedNames {
  // Blocked anywhere, even inside a longer word and with spaces, - or _
  // in between ("f u c k", "xfuckx"). Only strong words that practically
  // never appear inside normal names belong here.
  static const List<String> anywhere = [
    // English
    'fuck', 'phuck', 'shit', 'cunt', 'bitch', 'bastard', 'whore', 'slut',
    'wanker', 'wanking', 'twat', 'pussy', 'asshole', 'cocksucker',
    'dickhead', 'penis', 'vagina', 'dildo', 'porn', 'jizz', 'blowjob',
    'handjob', 'piss', 'retard', 'nigger', 'nigga', 'faggot', 'tranny',
    'pedophile', 'paedophile', 'molest', 'incest', 'hitler',
    // German
    'fotze', 'votze', 'arschloch', 'wichser', 'wixer', 'wichs', 'ficken',
    'ficker', 'fickt', 'hurensohn', 'schlampe', 'schwuchtel', 'missgeburt',
    'behindert', 'spast', 'neger', 'kanake', 'pimmel', 'titten', 'bumsen',
    'muschi', 'scheis', 'siegheil',
  ];

  // Short words that are only blocked on their own ("Ass", "Big Ass",
  // "A s s"), because they also appear inside harmless words
  // ("Cassandra", "Dickens", "Peacock", "Essex", "Fukuda", "Swanky",
  // "Therapist").
  static const List<String> wholeWordOnly = [
    // English
    'ass', 'arse', 'dick', 'cock', 'cum', 'sex', 'tits', 'boobs', 'anal',
    'anus', 'fag', 'rape', 'rapist', 'pedo', 'paedo', 'wank', 'fuk', 'fck',
    'coon', 'spic', 'chink', 'kike', 'nazi', 'nazis', 'kkk',
    // German
    'arsch', 'fick', 'hure', 'huren', 'nutte', 'nutten', 'schwanz', 'mongo',
  ];

  // ---- The check (the rules do exactly the same) ----

  // Each [characters, replacement] pair is applied in this order
  static const List<List<String>> replacements = [
    ['[äàáâãå]', 'a'],
    ['[öòóôõø]', 'o'],
    ['[üùúû]', 'u'],
    ['[éèêë]', 'e'],
    ['[íìîï]', 'i'],
    ['ß', 'ss'],
    ['ñ', 'n'],
    ['ç', 'c'],
    ['0', 'o'],
    ['1', 'i'],
    ['3', 'e'],
    ['4', 'a'],
    ['5', 's'],
    ['7', 't'],
  ];

  // "fuck" becomes "f+u+c+k+": each letter may be repeated
  static String _pattern(List<String> words) =>
      words.map((word) => word.split('').map((c) => '$c+').join()).join('|');

  // The patterns, written so that they work the same in Dart and in the
  // rules (both check that the WHOLE text matches)
  static String get anywherePattern => '.*(${_pattern(anywhere)}).*';
  static String get wholeWordPattern =>
      '(.*[ _-])?(${_pattern(wholeWordOnly)})([ _-].*)?';
  static String get compactWholeWordPattern => '(${_pattern(wholeWordOnly)})';

  static final _anywhere = RegExp('^$anywherePattern\$');
  static final _wholeWord = RegExp('^$wholeWordPattern\$');
  static final _compactWholeWord = RegExp('^$compactWholeWordPattern\$');

  // True if the name contains a blocked word
  static bool contains(String name) {
    var cleaned = name.toLowerCase();
    for (final pair in replacements) {
      cleaned = cleaned.replaceAll(RegExp(pair[0]), pair[1]);
    }
    // Without spaces, - and _: catches "f u c k" and "A s s"
    final compact = cleaned.replaceAll(RegExp('[ _-]'), '');
    return _anywhere.hasMatch(compact) ||
        _wholeWord.hasMatch(cleaned) ||
        _compactWholeWord.hasMatch(compact);
  }
}
