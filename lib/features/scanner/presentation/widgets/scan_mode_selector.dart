import 'package:flutter/material.dart';

import '../../../../core/models/scan_mode.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/chips/app_chip.dart';

/// Lets the user pick which of the three preview modes (Default,
/// Black and White, Enhance) is shown for the current page.
class ScanModeSelector extends StatelessWidget {
  final ScanMode selected;
  final ValueChanged<ScanMode> onChanged;

  const ScanModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Preview mode',
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final mode in ScanMode.values)
            AppChip(
              label: mode.label,
              selected: selected == mode,
              onSelected: (_) => onChanged(mode),
            ),
        ],
      ),
    );
  }
}
