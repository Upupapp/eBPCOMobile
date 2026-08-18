import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/models/application_model.dart';
import '../../../../../core/models/lifecycle_status.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// The persistent banner at the top of an application's detail.
///
/// Guarantees the acceptance criterion that an application with an open
/// Letter of Instruction can never reach a state where the applicant sees no
/// route to resolve it: the banner is derived from the record itself, so it
/// appears wherever the condition holds rather than having to be remembered
/// at each call site.
class DetailActionBanner extends StatelessWidget {
  final ApplicationModel application;

  const DetailActionBanner({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final letter = application.openInstruction;
    if (letter != null) {
      return _Banner(
        icon: Icons.assignment_late_outlined,
        tone: AppColors.statusRejected,
        background: AppColors.statusRejectedBg,
        title: 'Letter of Instruction outstanding',
        body: letter.openCount == 1
            ? '1 item must be corrected before this application can proceed.'
            : '${letter.openCount} items must be corrected before this '
                  'application can proceed.',
        actionLabel: 'Open the letter',
        onTap: () =>
            context.push('/applications/${application.id}/instructions'),
      );
    }

    final status = application.lifecycleStatus;

    if (status == ApplicationLifecycleStatus.revisionRequired) {
      final evaluation = application.returningEvaluation;
      return _Banner(
        icon: Icons.edit_document,
        tone: AppColors.statusPending,
        background: AppColors.statusPendingBg,
        title: 'Returned for revision',
        // Verbatim remark. Paraphrasing an evaluator would leave the applicant
        // guessing at what was actually asked of them.
        body: evaluation?.remarks ??
            'An evaluator returned this application for correction.',
        actionLabel: 'See the evaluation',
        onTap: null,
      );
    }

    if (status == ApplicationLifecycleStatus.assessed) {
      return _Banner(
        icon: Icons.receipt_long_outlined,
        tone: AppColors.statusPending,
        background: AppColors.statusPendingBg,
        title: 'Order of Payment ready',
        body: 'Fees have been assessed and are now due.',
        actionLabel: 'View Order of Payment',
        onTap: () => context.push('/applications/${application.id}/pay'),
      );
    }

    if (status == ApplicationLifecycleStatus.readyForRelease) {
      return _Banner(
        icon: Icons.inventory_2_outlined,
        tone: AppColors.statusApproved,
        background: AppColors.statusApprovedBg,
        title: 'Ready to claim',
        body: 'Your permit has been generated and is waiting for release.',
        actionLabel: 'Claim instructions',
        onTap: () => context.push('/applications/${application.id}/permit'),
      );
    }

    if (status == ApplicationLifecycleStatus.rejected ||
        status == ApplicationLifecycleStatus.cancelled ||
        status == ApplicationLifecycleStatus.expired) {
      return _Banner(
        icon: Icons.report_gmailerrorred_outlined,
        tone: AppColors.statusRejected,
        background: AppColors.statusRejectedBg,
        title: status == ApplicationLifecycleStatus.rejected
            ? 'Application not approved'
            : status!.adminLabel,
        body: application.returningEvaluation?.remarks ??
            status!.applicantSubLine,
        actionLabel: 'What you can do',
        onTap: () => context.push('/applications/${application.id}/outcome'),
      );
    }

    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final Color background;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback? onTap;

  const _Banner({
    required this.icon,
    required this.tone,
    required this.background,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: tone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tone, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.cardTitle.copyWith(color: tone),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTypography.body),
          if (onTap != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: tone,
                  minimumSize: const Size(0, AppConstants.minTouchTarget),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
