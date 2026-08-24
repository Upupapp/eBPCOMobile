import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/application_model.dart';
import '../../../../core/providers/applications_provider.dart';

/// Records a construction-permit submission as a real application.
///
/// Before this existed, the sixteen permit wizards ended their submit handler
/// by flipping their own draft's status to `submitted`, inventing a reference
/// number locally, and navigating to a confirmation screen. Nothing else
/// happened. `ApplicationsProvider` — which is the only thing
/// `ApplicationListScreen` reads — never heard about it.
///
/// The applicant's experience of that: fill in nine steps, press Submit, read
/// a reference number, then find the applications list exactly as empty as
/// before. No notification either, since the submitted notification is posted
/// by `ApplicationsProvider.submitApplication` and that was never reached.
///
/// The reference number the wizard already generated is passed through rather
/// than replaced, so the number on the confirmation screen and the number in
/// the list are the same number. On a live build the server assigns its own
/// and the parsed response wins.
///
/// [applicantName] fills `businessName`. A construction permit is filed by a
/// person, not a business, and that field is what the detail screen labels
/// "Business" — worth revisiting when the backend defines the real shape.
///
/// Returns null when the submission could not be recorded, having already told
/// the applicant. Failure is handled here rather than in sixteen wizards for
/// the usual reason, and because the alternative was worse than untidy: an
/// unguarded throw skipped the `pushReplacement` below every call site, so
/// pressing Submit did nothing at all — no confirmation, no error, no way to
/// tell whether nine steps of work had been filed.
///
/// The draft is deliberately left alone on failure. The applicant is still on
/// the last step with everything they entered, and can press Submit again.
Future<ApplicationModel?> submitPermitApplication(
  BuildContext context, {
  required String referenceNumber,
  required String permitTypeLabel,
  required String applicantName,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    return await context.read<ApplicationsProvider>().submitApplication(
      businessId: '',
      businessName: applicantName,
      // The only options are new/renewal/amendment. Every permit wizard files
      // a new one; [permitTypeLabel] is what actually names it on screen.
      type: ApplicationType.newPermit,
      documents: const [],
      permitTypeLabel: permitTypeLabel,
      applicationNumber: referenceNumber,
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Could not submit your application. Check your connection and try '
          'again — nothing you entered has been lost.',
        ),
      ),
    );
    return null;
  }
}

/// What to call the applicant on the application record.
///
/// Sixteen wizards each hold their own applicant class — there is no shared
/// interface — so they pass the three fields rather than the object, and the
/// rule for choosing between them lives here once.
///
/// The enterprise wins when there is one: a permit filed under a construction
/// firm should read as that firm, not as whoever typed the form.
String applicantDisplayName({
  required String enterpriseName,
  required String firstName,
  required String lastName,
}) {
  final enterprise = enterpriseName.trim();
  if (enterprise.isNotEmpty) return enterprise;
  return '$firstName $lastName'.trim();
}
