import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// The Home screen's entry point into the document scanner: a circular
/// floating action button, positioned by the caller's `Scaffold` above the
/// bottom navigation bar. Hides itself while the on-screen keyboard is open
/// so it never floats over a keyboard or the field the user is editing.
class ScannerFab extends StatelessWidget {
  final VoidCallback onPressed;

  const ScannerFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (keyboardOpen) return const SizedBox.shrink();

    return Semantics(
      label: 'Scan Document',
      button: true,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 6,
        tooltip: 'Scan Document',
        child: const Icon(Icons.document_scanner_outlined),
      ),
    );
  }
}
