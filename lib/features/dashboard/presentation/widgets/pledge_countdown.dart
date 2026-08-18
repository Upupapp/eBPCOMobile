import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/permit_classification.dart';
import '../../../../core/services/service_pledge_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// The RA 11032 service-pledge countdown for one application.
///
/// Renders "Awaiting classification" when [pledge] is null. That case is not a
/// missing value to be papered over with a zero — until the LGU classifies the
/// application there is no pledge to count against, and inventing one would
/// have the app accuse the office of missing a deadline it never set.
class PledgeCountdown extends StatelessWidget {
  final ServicePledge? pledge;

  const PledgeCountdown({super.key, required this.pledge});

  @override
  Widget build(BuildContext context) {
    final current = pledge;
    if (current == null) {
      return _Chip(
        icon: Icons.schedule_outlined,
        label: 'Awaiting classification',
        semanticLabel:
            'Awaiting classification. The office has not yet set a target '
            'release date for this application.',
        foreground: AppColors.textSecondary,
        background: AppColors.surfaceMuted,
      );
    }

    if (current.hasLapsed) {
      return _Chip(
        icon: Icons.error_outline,
        label: 'Past target date',
        semanticLabel:
            'This application has passed its '
            '${current.classification.prescribedWorkingDays} working day '
            'service pledge.',
        foreground: AppColors.statusRejected,
        background: AppColors.statusRejectedBg,
      );
    }

    final days = current.workingDaysRemaining;
    final unit = days == 1 ? 'working day' : 'working days';
    final soon = current.isDueSoon;

    return _Chip(
      icon: Icons.timer_outlined,
      label: '$days $unit left',
      semanticLabel:
          '$days $unit remaining of the '
          '${current.classification.label} service pledge.'
          '${current.calendarIncomplete ? ' Approximate — the holiday calendar for this period is incomplete.' : ''}',
      foreground: soon ? AppColors.statusPending : AppColors.statusInfo,
      background: soon ? AppColors.statusPendingBg : AppColors.statusInfoBg,
      approximate: current.calendarIncomplete,
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String semanticLabel;
  final Color foreground;
  final Color background;
  final bool approximate;

  const _Chip({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.foreground,
    required this.background,
    this.approximate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                approximate ? '~$label' : label,
                style: AppTypography.helper.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
