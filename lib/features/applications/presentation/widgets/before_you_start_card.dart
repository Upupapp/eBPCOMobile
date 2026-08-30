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
    // draft died with the process. Widened 30 August when all nineteen
    // wizards began to persist, with the caveat that files were not kept —
    // a picked file's path was not reliably readable after a restart.
    // Widened again the same day, once attachments were copied into the
    // app's own storage and stored by NAME rather than by path: they are
    // kept now, and the draft names anything it cannot give back. Gated
    // both ways by honest_assurances_test.
    'You can save your progress as a draft and come back to it later, '
        'even after closing the app. Your attached files are kept too — if '
        'any are missing when you return, the draft will say which.',
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
