import 'package:flutter/material.dart';

import '../../../../../shared/widgets/states/empty_state.dart';

/// Placeholder for Step 6 — Consent and Authorization. Reached once Steps
/// 1-5 are complete; the wizard shell's progress header already shows
/// "Step 6 of 9" and this step's title/subtitle, so this page only needs
/// to reinforce that the step isn't built yet. No fields are implemented
/// here per the current scope.
class Step6Placeholder extends StatelessWidget {
  const Step6Placeholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.construction_outlined,
      title: 'Coming Soon',
      message: 'This step will be implemented next.',
    );
  }
}
