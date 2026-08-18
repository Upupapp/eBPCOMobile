import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/action_item.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// One outstanding obligation, rendered at the very top of Home.
///
/// Deliberately loud: a Letter of Instruction or an overdue Order of Payment
/// is the single most consequential thing the app can tell an applicant, and
/// the cost of them missing it is a lapsed application.
class ActionRequiredCard extends StatelessWidget {
  final ActionItem item;
  final VoidCallback onTap;

  const ActionRequiredCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.isCritical
        ? AppColors.statusRejected
        : AppColors.statusPending;
    final accentBackground = item.isCritical
        ? AppColors.statusRejectedBg
        : AppColors.statusPendingBg;

    return Semantics(
      button: true,
      label:
          'Action required: ${item.title}. ${item.detail} '
          'Application ${item.applicationNumber}.',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppConstants.minTouchTarget,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
              border: Border.all(color: accent, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: accentBackground,
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusSmall,
                        ),
                      ),
                      child: Icon(item.icon, size: 20, color: accent),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.cardTitle.copyWith(
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(item.detail, style: AppTypography.bodyMuted),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${item.permitTypeLabel} · ${item.applicationNumber}',
                  style: AppTypography.helper,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      minimumSize: const Size(0, AppConstants.minTouchTarget),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.actionLabel),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
