import 'package:flutter/material.dart';

import 'package:survivor_test/data/online_player.dart';
import 'package:survivor_test/overlays/menu_colors.dart';

// Opens the window where the player chooses their leaderboard name.
// The first time (canCancel: false) it can only be closed with a valid name.
// Later, from the start screen, it can also be cancelled.
// Finishes once the window is closed.
Future<void> showNameDialog(
  BuildContext context, {
  required bool canCancel,
}) {
  return showDialog<void>(
    context: context,
    // Tapping outside the window only closes it if cancelling is allowed
    barrierDismissible: canCancel,
    builder: (_) => _NameDialog(canCancel: canCancel),
  );
}

class _NameDialog extends StatefulWidget {
  final bool canCancel;
  const _NameDialog({required this.canCancel});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  // Holds the text in the input box. Starts with the current name, if any.
  late final TextEditingController _controller = TextEditingController(
    text: OnlinePlayer.name ?? '',
  );

  String? get _problem => OnlinePlayer.nameProblem(_controller.text);

  // A controller must be thrown away when the window closes
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_problem != null) return;
    await OnlinePlayer.saveName(_controller.text);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    // Only show a hint once the player has started typing
    final showHint = problem != null && _controller.text.isNotEmpty;
    return PopScope(
      // The Android back button can't close the window the first time
      canPop: widget.canCancel,
      child: AlertDialog(
        // In landscape the keyboard covers most of the screen: let the
        // window scroll instead of overflowing, and keep its margins small
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        backgroundColor: blackTextColor,
        title: const Text(
          'Choose your name for the global leaderboard',
          style: TextStyle(color: whiteTextColor, fontSize: 20),
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLength: OnlinePlayer.maxNameLength,
            style: const TextStyle(color: whiteTextColor, fontSize: 22),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              errorText: showHint ? problem : null,
              counterStyle: const TextStyle(color: whiteTextColor),
            ),
            // Redraw on every key press so the hint and OK button update
            onChanged: (_) => setState(() {}),
            // The keyboard's "done" key works like OK
            onSubmitted: (_) => _save(),
          ),
        ),
        actions: [
          if (widget.canCancel)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: whiteTextColor, fontSize: 20),
              ),
            ),
          ElevatedButton(
            // Greyed out until the name is valid
            onPressed: problem == null ? _save : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: whiteTextColor,
              disabledBackgroundColor: Colors.grey.shade700,
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: blackTextColor, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
