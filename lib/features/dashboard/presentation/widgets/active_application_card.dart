import 'package:flutter/material.dart';

import '../../../../core/models/application_model.dart';
import '../../../../core/services/service_pledge_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/cards/tracking_card.dart';
import 'pledge_countdown.dart';

/// Card showing one in-flight application: the applicant-facing status
/// headline, the admin's own sub-line beneath it, and the RA 11032 service
/// pledge countdown.
///
/// The sub-line matters as much as the headline. "Under Review" is true of
/// document verification, technical evaluation, and a revision the applicant
/// has to act on — three very different situations for the person waiting.
class ActiveApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final ServicePledge? pledge;
  final VoidCallback onViewDetails;

  const ActiveApplicationCard({
    super.key,
    required this.application,
    required this.onViewDetails,
    this.pledge,
  });

  @override
  Widget build(BuildContext context) {
    final status = application.applicantStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackingCard(
          trackingId: application.applicationNumber,
          title: application.businessName,
          subtitle: application.permitTypeLabel ?? application.type.label,
          statusLabel: status.label,
          statusColor: status.color,
          statusBackgroundColor: status.backgroundColor,
          progress: application.progress,
          footerText: application.statusSubLine ?? application.nextStep,
          actionLabel: 'View Details',
          onAction: onViewDetails,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: PledgeCountdown(pledge: pledge),
        ),
      ],
    );
  }
}
