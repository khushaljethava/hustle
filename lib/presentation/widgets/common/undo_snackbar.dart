import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Shows a snackbar with an UNDO action after a delete.
///
/// Usage:
/// ```dart
/// showUndoSnackBar(
///   context,
///   message: 'Time entry deleted',
///   onUndo: () => restoreEntry(),
/// );
/// ```
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppTheme.secondaryColor,
          onPressed: onUndo,
        ),
      ),
    );
}
