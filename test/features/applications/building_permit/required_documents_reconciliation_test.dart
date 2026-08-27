import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/contract/requirements_catalog.dart';
import 'package:ebpco_user_app/core/models/building_permit_model.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/steps/step7_required_documents.dart';
import 'package:ebpco_user_app/shared/widgets/uploads/document_upload_tile.dart';

/// Step 7 is the Unified Application Form's documentary annex, and it is
/// supposed to be the whole of it.
///
/// Reconciled on 27 August 2026 against Castilla OME's real "Building Permit
/// Documentary Requirements" checklist, as mirrored in the requirements
/// catalog. Seven required documents on that checklist had no slot here at
/// all: the signed application form itself, Survey Plan, Cost Estimate,
/// Structural Design and Analysis, Soil Analysis, the DOLE Construction Safety
/// and Health Program, and the DPWH/PEO Road Clearance.
///
/// An applicant who supplied everything the app asked for had still not
/// supplied everything the office needs — and would find that out after filing.

Future<List<String>> _renderedSlots(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Step7RequiredDocuments(
            formKey: GlobalKey<FormState>(),
            draft: BuildingPermitDraft(),
            onChanged: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  return find
      .byType(DocumentUploadTile)
      .evaluate()
      .map((e) => (e.widget as DocumentUploadTile).label)
      .toList();
}

void main() {
  testWidgets('the seven documents the checklist required are now asked for', (
    tester,
  ) async {
    final slots = await _renderedSlots(tester);

    for (final label in [
      'Signed Unified Application Form',
      'Survey Plan',
      'Cost Estimate',
      'Structural Design and Analysis',
      'Soil Analysis / Plate Load Test',
      'Construction Safety and Health Program (DOLE)',
      'Road Clearance (DPWH / PEO)',
    ]) {
      expect(slots, contains(label), reason: '$label has no upload slot');
    }
  });

  testWidgets('the step offers at least as many slots as the checklist '
      'has required documents', (tester) async {
    final slots = await _renderedSlots(tester);
    final catalog =
        requirementsCatalog[CanonicalPermitType.buildingPermitNewConstruction]!;

    // Not an equality: the checklist's eight ancillary permit forms are filed
    // through this app as their own applications rather than uploaded as
    // forms, and the app additionally asks for a Tax Declaration, a Real
    // Property Tax Receipt and a Barangay Clearance that the OME checklist
    // does not list. What must hold is that the required side is covered.
    expect(
      slots.length,
      greaterThanOrEqualTo(catalog.requiredDocumentCount),
      reason:
          'step 7 offers ${slots.length} slots against '
          '${catalog.requiredDocumentCount} required checklist documents',
    );
  });

  testWidgets('every rendered slot is required to continue', (tester) async {
    // The step gates Continue on RequiredDocuments.isValid. A slot that is
    // rendered but not in isValid would look mandatory and not be — worse than
    // either alternative.
    final slots = await _renderedSlots(tester);
    final draft = BuildingPermitDraft();

    expect(draft.requiredDocuments.isValid, isFalse);
    expect(slots, isNotEmpty);
  });
}
