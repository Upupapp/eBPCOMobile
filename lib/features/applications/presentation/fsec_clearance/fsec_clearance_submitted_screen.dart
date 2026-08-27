import 'package:flutter/material.dart';

import '../../../../core/contract/admin_vocabulary.dart';
import '../widgets/application_submitted_view.dart';

/// Terminal confirmation screen for the FSEC application.
///
/// The notice names the permit this clearance unblocks, because that is why
/// almost every applicant is here.
class FsecClearanceSubmittedScreen extends StatelessWidget {
  final String referenceNumber;
  final DateTime submissionDate;

  /// Null when the wizard did not create a record — kept nullable so a
  /// route entered directly, without `extra`, still renders.
  final String? applicationId;

  const FsecClearanceSubmittedScreen({
    super.key,
    required this.referenceNumber,
    required this.submissionDate,
    this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationSubmittedView(
      headline: 'Fire Safety Evaluation Clearance Applied For!',
      body:
          'Your FSEC application has been submitted to the Bureau of Fire Protection. The Bureau evaluates your submitted plans before the Building Permit can be issued.',
      notice:
          'Your Building Permit cannot be issued until this clearance is granted.',
      applicationId: applicationId,
      referenceNumber: referenceNumber,
      submissionDate: submissionDate,
      facts: [
        (
          label: 'Application Type',
          value: CanonicalPermitType.fsecForBuildingPermitBfp.wire,
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
