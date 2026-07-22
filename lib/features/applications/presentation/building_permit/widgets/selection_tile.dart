import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/cards/app_card.dart';

/// Accessible selection card used throughout the Building Permit wizard for
/// single-choice (radio) and multi-choice (checkbox) options — the same
/// "selectable AppCard with a manual indicator icon" pattern already used
/// by the Payment flow's method picker, promoted here since this wizard
/// needs it repeatedly (Occupancy group, Scope of work, Payment method).
class SelectionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool multiSelect;

  const SelectionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.multiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: subtitle == null ? title : '$title. $subtitle',
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        backgroundColor: selected ? AppColors.lightBlue : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? (multiSelect
                        ? Icons.check_box_rounded
                        : Icons.radio_button_checked_rounded)
                  : (multiSelect
                        ? Icons.check_box_outline_blank_rounded
                        : Icons.radio_button_unchecked_rounded),
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyStrong),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.helper),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
