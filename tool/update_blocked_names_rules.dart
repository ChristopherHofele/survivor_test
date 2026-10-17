// Writes the blocked-names check from lib/data/blocked_names.dart into
// firestore.rules, so the game and the server always use the same list.
//
// Run it from the project folder after changing the list:
//     dart run tool/update_blocked_names_rules.dart
// Then paste firestore.rules into the Firebase console again.
import 'dart:io';

import 'package:survivor_test/data/blocked_names.dart';

const beginMarker = 'BEGIN BLOCKED NAMES';
const endMarker = 'END BLOCKED NAMES';

void main() {
  final file = File('firestore.rules');
  final lines = file.readAsStringSync().replaceAll('\r\n', '\n').split('\n');
  final begin = lines.indexWhere((line) => line.contains(beginMarker));
  final end = lines.indexWhere((line) => line.contains(endMarker));
  if (begin == -1 || end < begin) {
    stderr.writeln('Could not find the $beginMarker / $endMarker lines.');
    exit(1);
  }

  final replacements = BlockedNames.replacements
      .map((pair) => "\n        .replace('${pair[0]}', '${pair[1]}')")
      .join();
  final generated = '''
    // $beginMarker: written by tool/update_blocked_names_rules.dart from
    // lib/data/blocked_names.dart. Don't change it here by hand.
    function isBlockedName(name) {
      let cleaned = name.lower()$replacements;
      let compact = cleaned.replace('[ _-]', '');
      return compact.matches('${BlockedNames.anywherePattern}')
        || cleaned.matches('${BlockedNames.wholeWordPattern}')
        || compact.matches('${BlockedNames.compactWholeWordPattern}');
    }
    // $endMarker''';

  lines.replaceRange(begin, end + 1, generated.split('\n'));
  // The project uses Windows line endings
  file.writeAsStringSync(lines.join('\r\n'));
  stdout.writeln('Updated the blocked names in firestore.rules.');
}
