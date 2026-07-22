import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/building_permit_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../../../../shared/widgets/states/empty_state.dart';

const _milestones = [
  'Submitted for Assessment',
  'Under Review by the Office of the Building Official',
  'Assessment and Fees Confirmed',
  'Payment Verification',
  'Approved and Ready for Release',
];

/// Simple tracking view for the just-submitted Building Permit
/// application. This prototype does not simulate further status
/// advancement — only the submitted milestone is marked complete, matching
/// the Application Tracking Stitch's vertical timeline pattern.
class BuildingPermitStatusScreen extends StatelessWidget {
  const BuildingPermitStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<BuildingPermitProvider>().draft;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Application Status')),
      body: SafeArea(
        child: draft == null || draft.referenceNumber == null
            ? const EmptyState(
                icon: Icons.description_outlined,
                title: 'No submitted application',
                message:
                    'Submit a Building Permit application to see its status here.',
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppCard(
                    backgroundColor: AppColors.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reference Number',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textOnPrimaryMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          draft.referenceNumber!,
                          style: AppTypography.statistic.copyWith(
                            color: AppColors.textOnPrimary,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          draft.submittedDate != null
                              ? 'Submitted ${dateFormat.format(draft.submittedDate!)}'
                              : '',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textOnPrimaryMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Status Timeline', style: AppTypography.cardTitle),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _milestones.length; i++)
                          _TimelineRow(
                            label: _milestones[i],
                            isDone: i == 0,
                            isCurrent: i == 0,
                            isLast: i == _milestones.length - 1,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'The Office of the Building Official will review your '
                    'application and documents next. This prototype does not '
                    'simulate further status changes.',
                    style: AppTypography.helper,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Return to Applications',
                    onPressed: () => context.go('/app/applications'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _TimelineRow({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.statusApproved : AppColors.textMuted;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: color,
              ),
              if (!isLast)
                Container(width: 2, height: 32, color: AppColors.borderLight),
            ],
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                label,
                style: isCurrent
                    ? AppTypography.bodyStrong
                    : AppTypography.bodyMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
