import 'package:flutter/material.dart';

import '../../../../core/contract/admin_vocabulary.dart';
import '../widgets/application_submitted_view.dart';

/// Terminal confirmation screen shown once the application is submitted.
/// Sits outside the numbered wizard steps, matching how every other permit
/// wizard closes out its flow.
class InteriorDesignApplicationSubmittedScreen extends StatelessWidget {
  final String referenceNumber;
  final DateTime submissionDate;

  /// Null when the wizard did not create a record — kept nullable so a
  /// route entered directly, without `extra`, still renders.
  final String? applicationId;
  final String relatedBuildingPermitNumber;
  final String relatedBuildingPermitStatus;

  const InteriorDesignApplicationSubmittedScreen({
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
      headline: 'Interior Design Application Submitted!',
      body:
          'Your Interior Design Permit application has been submitted for '
          'initial review. You will be notified once the Office of '
          'the Building Official completes the assessment of your '
          'application.',
      notice: isPending
          ? 'This permit cannot be valid or issued until '
                'your related Building Permit is approved.'
          : null,
      applicationId: applicationId,
      referenceNumber: referenceNumber,
      submissionDate: submissionDate,
      facts: [
        (
          label: 'Application Type',
          value: CanonicalPermitType.interiorDesignPermit.wire,
        ),
        (
          label: 'Related Building Permit',
          value: relatedBuildingPermitNumber.trim().isEmpty
              ? 'Not yet assigned'
              : relatedBuildingPermitNumber,
        ),
        (
          label: 'Related Building Permit Status',
          value: relatedBuildingPermitStatus,
        ),
        (label: 'Status', value: 'Submitted for Initial Review'),
      ],
      secondaryLabel: 'View Application',
      secondaryRoute: '/app/applications',
      primaryLabel: 'Return to Applications',
      primaryRoute: '/app/applications',
    );
  }
}
