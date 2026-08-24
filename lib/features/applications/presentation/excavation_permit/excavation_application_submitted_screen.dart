import 'package:flutter/material.dart';

import '../widgets/application_submitted_view.dart';

/// Terminal confirmation screen shown once the application is submitted.
/// Sits outside the numbered wizard steps, matching how every other permit
/// wizard closes out its flow.
///
/// The notice here says something different from the other permits — that
/// this permit does not guarantee the related Building Permit will be
/// granted, rather than that it cannot be issued until it is.
class ExcavationApplicationSubmittedScreen extends StatelessWidget {
  final String referenceNumber;
  final DateTime submissionDate;

  /// Null when the wizard did not create a record — kept nullable so a
  /// route entered directly, without `extra`, still renders.
  final String? applicationId;
  final String relatedBuildingPermitNumber;
  final String relatedBuildingPermitStatus;

  const ExcavationApplicationSubmittedScreen({
    super.key,
    required this.referenceNumber,
    required this.submissionDate,
    this.applicationId,
    required this.relatedBuildingPermitNumber,
    required this.relatedBuildingPermitStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = relatedBuildingPermitStatus != 'Approved';

    return ApplicationSubmittedView(
      headline: 'Excavation & Ground Preparation Application Submitted!',
      body:
          'Your Excavation & Ground Preparation Permit application has been submitted for '
          'initial review. You will be notified once the Office of '
          'the Building Official completes the assessment of your '
          'application.',
      notice: isPending
          ? 'This permit does not guarantee the granting of '
            'your related Building Permit application.'
          : null,
      applicationId: applicationId,
      referenceNumber: referenceNumber,
      submissionDate: submissionDate,
      facts: [
        (label: 'Application Type', value: 'Excavation & Ground Preparation Permit'),
        (label: 'Related Building Permit', value: relatedBuildingPermitNumber.trim().isEmpty
              ? 'Not yet assigned'
              : relatedBuildingPermitNumber),
        (label: 'Related Building Permit Status', value: relatedBuildingPermitStatus),
        (label: 'Status', value: 'Submitted for Initial Review'),
      ],
      secondaryLabel: 'View Application',
      secondaryRoute: '/app/applications',
      primaryLabel: 'Return to Applications',
      primaryRoute: '/app/applications',
    );
  }
}
