import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Soft informational panel shown at the bottom of the Applications tab,
/// listing what to prepare before starting a new filing. Styled as
/// guidance (info-blue tone) rather than a warning.
class BeforeYouStartCard extends StatelessWidget {
  static const _checklist = [
    'Prepare all required documents and information.',
    'Ensure all details are accurate and complete.',
    // Narrowed 29 August 2026, when nothing was written to disk and every
    // draft died with the process; widened again 30 August, when M-48 made
    // all nineteen wizards persist. It says what is true of the new
    // behaviour AND what is not: the typing survives, the files do not,
    // because a picked file's path is not reliably readable after a
    // restart. Gated both ways by honest_assurances_test — the promise may
    // not come back without the caveat that makes it true.
    'You can save your progress as a draft and come back to it later, '
        'even after closing the app. Attached files are not kept — you '
        'will be asked to attach them again.',
    'Forms must be signed by a licensed engineer before submission.',
  ];

  const BeforeYouStartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statusInfoBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.statusInfo,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              // Expanded, as _ChecklistRow below already had it. Without it
              // the heading ran 10px past a 320dp screen.
              Expanded(
                child: Text(
                  'Before you start',
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.statusInfo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in _checklist) ...[
            _ChecklistRow(text: item),
            if (item != _checklist.last) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String text;

  const _ChecklistRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: AppColors.statusInfo,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMuted.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
