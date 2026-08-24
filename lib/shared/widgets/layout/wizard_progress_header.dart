import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The header every permit wizard shows above its current step: an
/// orientation line, the step counter, a progress bar, and the step's own
/// title and subtitle.
///
/// This lived as a private copy inside each of the sixteen wizard screens.
/// Fourteen were byte-identical and two differed only in how one string was
/// wrapped across source lines — which was enough for a scripted fix to the
/// 200% text-scale overflow to miss those two, so the duplication had already
/// produced a real inconsistency before it was removed.
///
/// The prose is bounded on purpose. The header sits above an
/// `Expanded(PageView)`, so anything unbounded here takes space from the form
/// itself; at 200% text scale an unbounded header consumed the whole viewport
/// and the applicant could not reach the fields. The step counter and the
/// progress bar stay unbounded — they are short, and they are the part that
/// must always be readable.
class WizardProgressHeader extends StatelessWidget {
  /// Zero-based index of the step on screen.
  final int currentStep;

  final int totalSteps;

  /// One line of orientation, e.g. "Complete your Building Permit application
  /// step by step."
  final String intro;

  /// The current step's own heading and explanation.
  final String title;
  final String subtitle;

  const WizardProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.intro,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPaddingHorizontal,
        AppSpacing.sm,
        AppConstants.screenPaddingHorizontal,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            intro,
            style: AppTypography.bodyMuted,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: AppTypography.label,
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            // A progress bar is invisible to a screen reader without this;
            // the step counter above it is text, but the bar is the thing
            // sighted users actually read the position from.
            label: 'Step ${currentStep + 1} of $totalSteps',
            value: '${(((currentStep + 1) / totalSteps) * 100).round()}%',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusXs,
              ),
              child: LinearProgressIndicator(
                value: (currentStep + 1) / totalSteps,
                minHeight: 6,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.sectionTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodyMuted,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
