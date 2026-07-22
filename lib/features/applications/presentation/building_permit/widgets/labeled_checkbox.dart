import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Tappable row pairing a themed [Checkbox] with a label, used for the
/// wizard's declaration/consent acknowledgments. The label itself is part
/// of the tap target so it meets the minimum touch-target guidance without
/// needing a bigger checkbox.
class LabeledCheckbox extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const LabeledCheckbox({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: value,
      label: label,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(label, style: AppTypography.body),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
