import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/routes/wizard_routes.dart';

/// The permit-type → wizard table, against the router that has to serve it.
///
/// It used to be a private field on a private class inside the Applications
/// catalog screen. A second caller appeared — a renewal starts from an issued
/// permit and never sees that screen — and a hand-copied second table is the
/// shape this codebase has already grown four times over: a wizard header
/// copied sixteen times, a status badge hand-rolled five times, a confirmation
/// screen copied fifteen times.

void main() {
  final router = File('lib/routes/app_router.dart').readAsStringSync();

  test('every permit type the admin recognises has a wizard', () {
    for (final type in CanonicalPermitType.values) {
      expect(
        permitWizardRoutes[type],
        isNotNull,
        reason:
            '${type.wire} is filable in the admin and has no wizard here, so '
            'a renewal of one would have nowhere to go',
      );
    }
  });

  test('every route in the table is one the router declares', () {
    // A table entry with no route behind it is a button that opens the error
    // page, and only for the permit type nobody tested.
    for (final entry in permitWizardRoutes.entries) {
      expect(
        router,
        contains("path: '${entry.value}'"),
        reason:
            '${entry.key.wire} points at ${entry.value}, which the router '
            'does not declare',
      );
    }
  });

  test('no two permit types share a wizard', () {
    // Three Building Permit sub-types share one paper form, but not one
    // wizard: each collects different work. A duplicate here would file the
    // wrong permit type, which TAB 00 already caught happening five times.
    final routes = permitWizardRoutes.values.toList();
    expect(routes.toSet(), hasLength(routes.length));
  });

  test('the catalog screen no longer carries its own copy of the table', () {
    final catalog = File(
      'lib/features/applications/presentation/applications_screen.dart',
    ).readAsStringSync();

    // The legacy Business Permit route is the one exception and is named as
    // such; every other wizard route must come from the registry.
    final hardcoded = RegExp(r"'/applications/new/[a-z-]+'")
        .allMatches(catalog)
        .map((m) => m.group(0)!)
        .where((route) => !route.contains('business-permit'))
        .toSet();

    expect(
      hardcoded,
      isEmpty,
      reason: 'these routes are stated twice and will drift: $hardcoded',
    );
  });

  test('lookup by wire label finds the wizard', () {
    expect(
      wizardRouteForLabel('Fencing Permit'),
      '/applications/new/fencing-permit',
    );
    // The three sub-types are separate wizards despite sharing a form.
    expect(
      wizardRouteForLabel('Building Permit – Renovation / Alteration'),
      '/applications/new/renovation-permit',
    );
  });

  test('an unrecognised label has no wizard, and does not throw', () {
    // The legacy Business Permit flow is filed under a label deliberately
    // absent from the catalog. A renewal of one should read "not available",
    // not crash.
    expect(wizardRouteForLabel('Business Permit'), isNull);
  });

  test('every route an action item sends the applicant to is declared', () {
    // The expiry item was changed to point straight at the renewal rather
    // than at the record. A route in a string literal is exactly the kind of
    // thing that survives a rename and stops resolving.
    final actionItems = File(
      'lib/core/models/action_item.dart',
    ).readAsStringSync();
    final routes = RegExp(
      r"route: '(/applications/[^']*)'",
    ).allMatches(actionItems).map((m) => m.group(1)!).toSet();

    expect(routes, isNotEmpty);
    for (final route in routes) {
      // Interpolations stand in for the id; compare on the shape.
      final pattern = route.replaceAll(
        RegExp(r'\$\{[^}]*\}'),
        ':applicationId',
      );
      expect(
        router,
        contains("path: '$pattern'"),
        reason: '$route resolves to nothing',
      );
    }
  });
}
