import 'package:flutter/material.dart';

import '../../../../core/contract/admin_vocabulary.dart';
import '../widgets/application_submitted_view.dart';

/// Terminal confirmation screen for the FSIC application.
///
/// The notice names the permit this clearance unblocks, because that is why
/// almost every applicant is here.
class FsicClearanceSubmittedScreen extends StatelessWidget {
  final String referenceNumber;
  final DateTime submissionDate;

  /// Null when the wizard did not create a record — kept nullable so a
  /// route entered directly, without `extra`, still renders.
  final String? applicationId;

  const FsicClearanceSubmittedScreen({
    super.key,
    required this.referenceNumber,
    required this.submissionDate,
    this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationSubmittedView(
      headline: 'Fire Safety Inspection Certificate Applied For!',
      body:
          'Your FSIC application has been submitted to the Bureau of Fire Protection. The Bureau inspects the completed building before occupancy can be certified.',
      notice:
          'Your Certificate of Occupancy cannot be issued until this certificate is granted.',
      applicationId: applicationId,
      referenceNumber: referenceNumber,
      submissionDate: submissionDate,
      facts: [
        (
          label: 'Application Type',
          value: CanonicalPermitType.fsicForOccupancyPermitBfp.wire,
        ),
        (
          label: 'Reviewing Office',
          value: 'Municipal Planning and Development Office',
        ),
        (label: 'Valid For', value: '12 months from issuance'),
        (label: 'Status', value: 'Submitted for Initial Review'),
      ],
      secondaryLabel: 'View Application',
      secondaryRoute: '/app/applications',
      primaryLabel: 'Return to Applications',
      primaryRoute: '/app/applications',
    );
  }
}
