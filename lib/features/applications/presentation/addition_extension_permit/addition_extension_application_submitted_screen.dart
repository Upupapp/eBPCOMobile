import 'package:flutter/material.dart';

import '../widgets/application_submitted_view.dart';

/// Terminal confirmation screen shown once the application is submitted.
/// Sits outside the numbered wizard steps, matching how every other permit
/// wizard closes out its flow.
class AdditionExtensionApplicationSubmittedScreen extends StatelessWidget {
  final String referenceNumber;
  final DateTime submissionDate;

  /// Null when the wizard did not create a record — kept nullable so a
  /// route entered directly, without `extra`, still renders.
  final String? applicationId;

  const AdditionExtensionApplicationSubmittedScreen({
    super.key,
    required this.referenceNumber,
    required this.submissionDate,
    this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationSubmittedView(
      headline: 'Addition / Extension Application Submitted!',
      body:
          'Your Addition / Extension Permit application has been submitted for '
          'initial review. You will be notified once the Office of '
          'the Building Official completes the assessment of your '
          'application.',
      applicationId: applicationId,
      referenceNumber: referenceNumber,
      submissionDate: submissionDate,
      facts: [
        (label: 'Application Type', value: 'Building Permit — Addition / Extension'),
        (label: 'Official Scope of Work', value: 'Addition'),
        (label: 'Status', value: 'Submitted for Initial Review'),
      ],
      secondaryLabel: 'View Application',
      secondaryRoute: '/app/applications',
      primaryLabel: 'Return to Applications',
      primaryRoute: '/app/applications',
    );
  }
}
