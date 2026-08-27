import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/contract/admin_vocabulary.dart';
import '../../../../core/models/certificate_of_occupancy_model.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges/status_badge.dart';
import '../../../../shared/widgets/cards/app_card.dart';
import '../widgets/application_submitted_view.dart';

/// Terminal confirmation screen shown once the application is submitted.
/// Sits outside the numbered wizard steps, matching how every other permit
/// wizard closes out its flow.
class CertificateOfOccupancySubmittedScreen extends StatelessWidget {
  final String referenceNumber;
  final DateTime submissionDate;

  /// Null when the wizard did not create a record — kept nullable so a
  /// route entered directly, without `extra`, still renders.
  final String? applicationId;
  final String buildingPermitNumber;
  final String certificateType;

  const CertificateOfOccupancySubmittedScreen({
    super.key,
    required this.referenceNumber,
    required this.submissionDate,
    this.applicationId,
    required this.buildingPermitNumber,
    required this.certificateType,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationSubmittedView(
      headline: 'Certificate of Occupancy Application Submitted!',
      body:
          'Your Certificate of Occupancy application has been '
          'submitted for initial review. You will be notified as it '
          'moves through document verification, inspection, and '
          'evaluation.',
      applicationId: applicationId,
      referenceNumber: referenceNumber,
      submissionDate: submissionDate,
      facts: [
        (
          label: 'Application Type',
          value: CanonicalPermitType.certificateOfOccupancy.wire,
        ),
        (label: 'Related Building Permit', value: buildingPermitNumber.trim().isEmpty
              ? 'Not set'
              : buildingPermitNumber),
        (label: 'Certificate Type', value: certificateType),
        (label: 'Status', value: 'Submitted for Initial Review'),
      ],
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Application Status',
              style: AppTypography.cardTitle,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final stage in certificateStatusSequence) ...[
                  _StatusRow(
                    label: stage.label,
                    isCurrent:
                        stage == CertificateApplicationStatus.submitted,
                  ),
                  if (stage != certificateStatusSequence.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
      secondaryLabel: 'View Application',
      secondaryRoute: '/app/applications',
      primaryLabel: 'Return Home',
      primaryRoute: '/app/home',
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool isCurrent;

  const _StatusRow({required this.label, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isCurrent ? AppTypography.bodyStrong : AppTypography.body,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: StatusBadge(
            label: isCurrent ? 'Current' : 'Pending',
            color: isCurrent ? AppColors.statusApproved : AppColors.textMuted,
            backgroundColor: isCurrent
                ? AppColors.statusApprovedBg
                : AppColors.surfaceMuted,
          ),
        ),
      ],
    );
  }
}
