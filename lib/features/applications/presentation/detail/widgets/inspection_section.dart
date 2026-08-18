import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/models/application_detail.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// The joint inspection.
///
/// One event with every attending office listed, because Amended JMC 2021-01
/// requires LGUs to organise joint inspection teams so applicants stop having
/// to accommodate a separate visit from each office.
class InspectionSection extends StatelessWidget {
  final InspectionRecord inspection;

  const InspectionSection({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('EEEE, MMM d, yyyy');
    final time = DateFormat('h:mm a');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 20,
                color: AppColors.secondaryBlue,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  format.format(inspection.scheduledAt),
                  style: AppTypography.cardTitle,
                ),
              ),
            ],
          ),
          Text(
            time.format(inspection.scheduledAt),
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Attending offices',
            style: AppTypography.helper.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final office in inspection.offices)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusPill,
                    ),
                  ),
                  child: Text(
                    office,
                    style: AppTypography.helper.copyWith(
                      color: AppColors.secondaryBlueDark,
                    ),
                  ),
                ),
            ],
          ),
          if (inspection.preparationChecklist.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Have ready on site',
              style: AppTypography.helper.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final item in inspection.preparationChecklist)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_box_outline_blank,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(item, style: AppTypography.body),
                    ),
                  ],
                ),
              ),
          ],
          if (inspection.outcome != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Outcome: ${inspection.outcome}',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            if (inspection.remarks != null)
              Text(inspection.remarks!, style: AppTypography.bodyMuted),
          ],
        ],
      ),
    );
  }
}
