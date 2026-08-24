import 'package:flutter/material.dart';

import '../widgets/application_submitted_view.dart';

/// Terminal confirmation screen shown once the application is submitted.
/// Sits outside the numbered wizard steps, matching how every other permit
/// wizard closes out its flow.
class CivilStructuralApplicationSubmittedScreen extends StatelessWidget {
  final String referenceNumber;
  final DateTime submissionDate;
  final String relatedBuildingPermitNumber;
  final String relatedBuildingPermitStatus;

  const CivilStructuralApplicationSubmittedScreen({
    super.key,
    required this.referenceNumber,
    required this.submissionDate,
    required this.relatedBuildingPermitNumber,
    required this.relatedBuildingPermitStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = relatedBuildingPermitStatus != 'Approved';

    return ApplicationSubmittedView(
      headline: 'Civil / Structural Application Submitted!',
      body:
          'Your Civil / Structural Permit application has been submitted for '
          'initial review. You will be notified once the Office of '
          'the Building Official completes the assessment of your '
          'application.',
      notice: isPending
          ? 'This permit cannot be valid or issued until '
            'your related Building Permit is approved.'
          : null,
      referenceNumber: referenceNumber,
      submissionDate: submissionDate,
      facts: [
        (label: 'Application Type', value: 'Civil / Structural Permit'),
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
