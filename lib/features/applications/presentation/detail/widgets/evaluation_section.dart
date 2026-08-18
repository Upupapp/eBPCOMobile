import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/models/application_detail.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// The five OBO evaluation stages, always shown in full and in order.
///
/// Stages not yet reached are rendered as Pending rather than omitted, so the
/// applicant can see that Fire Safety and Final Approval are still ahead of
/// them instead of inferring it.
class EvaluationSection extends StatelessWidget {
  final List<EvaluationRecord> evaluations;

  const EvaluationSection({super.key, required this.evaluations});

  @override
  Widget build(BuildContext context) {
    final byStage = {for (final e in evaluations) e.stage: e};

    return Column(
      children: [
        for (final stage in EvaluationStage.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _StageTile(
              stage: stage,
              record:
                  byStage[stage] ??
                  EvaluationRecord(
                    stage: stage,
                    result: EvaluationResult.pending,
                  ),
            ),
          ),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  final EvaluationStage stage;
  final EvaluationRecord record;

  const _StageTile({required this.stage, required this.record});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');

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
              Expanded(
                child: Text(stage.label, style: AppTypography.cardTitle),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: record.result.backgroundColor,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusPill,
                  ),
                ),
                child: Text(
                  record.result.label,
                  style: AppTypography.helper.copyWith(
                    color: record.result.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(stage.plainDescription, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.xs),
          Text(stage.office, style: AppTypography.helper),
          if (record.evaluatedAt != null)
            Text(
              'Evaluated ${format.format(record.evaluatedAt!)}'
              '${record.evaluator != null ? ' by ${record.evaluator}' : ''}',
              style: AppTypography.helper,
            ),
          if (record.remarks != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: record.result.backgroundColor,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evaluator’s remarks',
                    style: AppTypography.helper.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Verbatim, in full. These remarks are the applicant's
                  // instructions and the admin makes them mandatory on a
                  // returned or rejected result.
                  Text(record.remarks!, style: AppTypography.body),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
