import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/application_model.dart';
import '../../../../core/services/service_pledge_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../dashboard/presentation/widgets/pledge_countdown.dart';

/// One application in the list: reference, permit type, status headline, the
/// action flag, and the pledged-date countdown.
class ApplicationListTile extends StatelessWidget {
  final ApplicationModel application;
  final ServicePledge? pledge;
  final VoidCallback onTap;

  const ApplicationListTile({
    super.key,
    required this.application,
    required this.onTap,
    this.pledge,
  });

  @override
  Widget build(BuildContext context) {
    final status = application.applicantStatus;
    final needsAction = application.requiresApplicantAction;

    return Material(
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
            border: Border.all(
              color: needsAction ? AppColors.statusRejected : AppColors.border,
              width: needsAction ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      application.permitTypeLabel ?? application.type.label,
                      style: AppTypography.cardTitle,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusPill,
                      ),
                    ),
                    child: Text(
                      status.label,
                      style: AppTypography.helper.copyWith(
                        color: status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(application.applicationNumber, style: AppTypography.helper),
              Text(application.businessName, style: AppTypography.bodyMuted),
              if (needsAction) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.priority_high_rounded,
                      size: 15,
                      color: AppColors.statusRejected,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Needs your action',
                        style: AppTypography.helper.copyWith(
                          color: AppColors.statusRejected,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (application.isInFlight) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PledgeCountdown(pledge: pledge),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
