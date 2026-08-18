import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/application_detail.dart';
import '../../../../core/models/lifecycle_status.dart';
import '../../../../core/providers/applications_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/widgets/states/empty_state.dart';

/// Why an application ended, and what the applicant can do about it.
///
/// A rejection is the point at which an applicant most needs to be told
/// something useful, and is exactly where permit systems most often show a red
/// badge and stop. This screen gives the verbatim reason, the stage that made
/// the decision, and the routes still open.
class ApplicationOutcomeScreen extends StatelessWidget {
  final String applicationId;

  const ApplicationOutcomeScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationsProvider>();
    final application = provider.byId(applicationId);
    final status = application?.lifecycleStatus;

    final isClosed =
        status == ApplicationLifecycleStatus.rejected ||
        status == ApplicationLifecycleStatus.cancelled ||
        status == ApplicationLifecycleStatus.expired;

    if (application == null || !isClosed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Outcome')),
        body: const EmptyState(
          icon: Icons.info_outline,
          title: 'Still in progress',
          message: 'This application has not reached a final outcome.',
        ),
      );
    }

    final evaluation = application.returningEvaluation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(status!.adminLabel)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.statusRejectedBg,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
                border: Border.all(color: AppColors.statusRejected),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status == ApplicationLifecycleStatus.rejected
                        ? 'Not approved'
                        : status.adminLabel,
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.statusRejected,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (evaluation != null) ...[
                    Text(
                      'Decided at the ${evaluation.stage.label} stage'
                      '${evaluation.evaluator != null ? ' by ${evaluation.evaluator}' : ''}.',
                      style: AppTypography.bodyMuted,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Text(
                    'Reason',
                    style: AppTypography.helper.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Verbatim, never paraphrased.
                  Text(
                    evaluation?.remarks ?? status.applicantSubLine,
                    style: AppTypography.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('What you can do', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            const _Option(
              icon: Icons.replay_outlined,
              title: 'File again',
              body:
                  'Correct what the evaluator identified and file a new '
                  'application. Your saved documents can be reused.',
            ),
            const _Option(
              icon: Icons.gavel_outlined,
              title: 'Appeal to the Building Official',
              body:
                  'You may ask the Office of the Building Official to '
                  'reconsider. Bring this reference and the evaluator’s '
                  'remarks.',
            ),
            const _Option(
              icon: Icons.support_agent_outlined,
              title: 'Ask the OBO',
              body:
                  'If the reason is unclear, contact the Office of the '
                  'Building Official before refiling — refiling with the same '
                  'defect will be returned again.',
            ),

            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Start a new application',
              icon: Icons.add_circle_outline,
              onPressed: () => context.push('/applications/new'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Back to application',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Option({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryBlue),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(body, style: AppTypography.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
