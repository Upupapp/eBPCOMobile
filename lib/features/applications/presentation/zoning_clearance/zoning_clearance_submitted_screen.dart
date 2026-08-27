import 'package:flutter/material.dart';

import '../../../../core/contract/admin_vocabulary.dart';
import '../widgets/application_submitted_view.dart';

/// Terminal confirmation screen shown once the application is submitted.
/// Sits outside the numbered wizard steps, matching how every other permit
/// wizard closes out its flow.
///
/// The notice says what a locational clearance is for, because most applicants
/// reach this wizard because another permit asked them for one.
class ZoningClearanceSubmittedScreen extends StatelessWidget {
  final String referenceNumber;
  final DateTime submissionDate;

  /// Null when the wizard did not create a record — kept nullable so a
  /// route entered directly, without `extra`, still renders.
  final String? applicationId;

  const ZoningClearanceSubmittedScreen({
    super.key,
    required this.referenceNumber,
    required this.submissionDate,
    this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationSubmittedView(
      headline: 'Zoning Clearance Application Submitted!',
      body:
          'Your Locational Clearance application has been submitted to the '
          'Municipal Planning and Development Office. A Zoning Officer will '
          'carry out an ocular inspection of the site before it is decided.',
      notice:
          'Many other permits ask for this clearance. Once it is issued you '
          'can attach it to those applications.',
      applicationId: applicationId,
      referenceNumber: referenceNumber,
      submissionDate: submissionDate,
      facts: [
        (
          label: 'Application Type',
          value: CanonicalPermitType.zoningLocationalClearance.wire,
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
