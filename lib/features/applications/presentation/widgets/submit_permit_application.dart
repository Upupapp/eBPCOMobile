import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/application_model.dart';
import '../../../../core/providers/application_intent_provider.dart';
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

  /// Where the work is, as one line.
  ///
  /// `POST /applications` has declared a nullable `location` string since the
  /// contract was written, and the app sent nothing — so an office receiving a
  /// filing knew the permit type and the applicant and not the site. Every
  /// wizard already collects a lot number, a street, a barangay and a city;
  /// they were simply never joined and never sent. Compose it with
  /// [constructionLocationLine].
  ///
  /// Null where the wizard has no site of its own — the two BFP clearances,
  /// which attach to a building permit that carries the address.
  String? location,

  /// Everything the applicant typed, from the wizard's own draft codec.
  ///
  /// Until 1 September 2026 no wizard sent any of it: a filing reached the
  /// office knowing the permit type, the applicant's name and the site line,
  /// and nothing from the nine or ten steps behind them. Build it with
  /// `permitFormPayload`.
  ///
  /// Null for a wizard with no draft codec, which is the honest state rather
  /// than an empty object — `{}` would assert the applicant entered nothing.
  Map<String, Object?>? form,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  // A renewal or amendment started elsewhere and walked the applicant into
  // this wizard. Consumed here rather than in sixteen wizards, and consumed
  // rather than read: an intent that survives its filing is one that can
  // attach itself to the next one.
  final lineage = context.read<ApplicationIntentProvider>().consumeFor(
    permitTypeLabel,
  );
  try {
    return await context.read<ApplicationsProvider>().submitApplication(
      businessId: '',
      businessName: applicantName,
      // New unless the applicant came in through a renewal or an amendment,
      // which the lineage is the authority on; [permitTypeLabel] is what
      // actually names the permit on screen.
      type: ApplicationType.newPermit,
      documents: const [],
      permitTypeLabel: permitTypeLabel,
      applicationNumber: referenceNumber,
      lineage: lineage,
      location: location,
      form: form,
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

/// Joins the parts of a site address into the one line the contract asks for.
///
/// Empty parts are dropped rather than rendered as commas: "Lot 12, , ,
/// Castilla" is worse than "Lot 12, Castilla", and an applicant who has not
/// been asked for a block number should not appear to have skipped one.
///
/// Returns null when nothing is known, because the contract types the field as
/// a string OR null and an empty string is neither.
String? constructionLocationLine({
  String? lot,
  String? block,
  String? street,
  String? barangay,
  String? city,
}) {
  final parts = [
    if ((lot ?? '').trim().isNotEmpty) 'Lot ${lot!.trim()}',
    if ((block ?? '').trim().isNotEmpty) 'Block ${block!.trim()}',
    ?_clean(street),
    ?_clean(barangay),
    ?_clean(city),
  ];
  return parts.isEmpty ? null : parts.join(', ');
}

String? _clean(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
