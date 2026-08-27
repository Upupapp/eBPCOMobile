import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/application_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A released permit, with its PD 1096 commencement deadline.
///
/// The deadline is on the tile rather than buried in the permit detail
/// because the consequence of missing it is total: PD 1096 voids a permit
/// where the authorised work is not commenced within one year of issue.
class PermitSummaryTile extends StatelessWidget {
  final ApplicationModel application;
  final DateTime asOf;
  final VoidCallback onTap;

  const PermitSummaryTile({
    super.key,
    required this.application,
    required this.asOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');
    final commenceBy = application.commenceByDate;
    final daysLeft = commenceBy == null
        ? null
        : DateTime(
            commenceBy.year,
            commenceBy.month,
            commenceBy.day,
          ).difference(DateTime(asOf.year, asOf.month, asOf.day)).inDays;
    final urgent = daysLeft != null && daysLeft <= 60;

    // The permit's own validity, shown only where it tells the applicant
    // something the commencement line does not. For a twelve-month type the
    // two dates coincide and a second identical line would just be noise; for
    // a six-month one the validity runs out first, and that is the date this
    // tile exists to surface.
    final expiry = application.expiryDate;
    final showExpiry =
        expiry != null && (commenceBy == null || expiry.isBefore(commenceBy));
    final expiryUrgent = application.expiryApproaching(asOf);

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
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 22,
                color: AppColors.statusApproved,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.permitNumber ?? 'Permit',
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      application.permitTypeLabel ?? application.type.label,
                      style: AppTypography.bodyMuted,
                    ),
                    if (showExpiry) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        application.expiredAsOf(asOf)
                            ? 'Expired (${format.format(expiry)})'
                            : 'Valid until ${format.format(expiry)}',
                        style: AppTypography.helper.copyWith(
                          color: expiryUrgent
                              ? AppColors.statusRejected
                              : AppColors.textSecondary,
                          fontWeight: expiryUrgent ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                    if (commenceBy != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        daysLeft != null && daysLeft < 0
                            ? 'Commencement deadline passed '
                                  '(${format.format(commenceBy)})'
                            : 'Work must start by ${format.format(commenceBy)}',
                        style: AppTypography.helper.copyWith(
                          color: urgent
                              ? AppColors.statusRejected
                              : AppColors.textSecondary,
                          fontWeight: urgent ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
