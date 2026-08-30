import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/building_permit_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';

/// The building permit's document step, against Castilla's own checklist.
///
/// `Building-Permit-and-Occupancy-Checklist.pdf` prints fourteen lines. The
/// catalogue entry was a faithful transcription of them — the step was not.
///
/// It made four documents mandatory that the checklist does not list at all,
/// and had no slot for one that it does. Each unlisted one is a trip to
/// another counter for a list the office does not keep.

const _step =
    'lib/features/applications/presentation/building_permit/steps/'
    'step7_required_documents.dart';

RequiredDocuments _complete() => RequiredDocuments()
  ..landTitleUpload = _doc
  ..validIdOfApplicantAndOwnerUpload = _doc
  ..plansUpload = _doc
  ..specificationsUpload = _doc
  ..prcIdChecklistUpload = _doc
  ..ptrChecklistUpload = _doc
  ..signedFormsUpload = _doc
  ..zoningClearanceUpload = _doc
  ..fireRelatedRequirementsUpload = _doc
  ..surveyPlanUpload = _doc
  ..costEstimateUpload = _doc
  ..structuralDesignAndAnalysisUpload = _doc
  ..soilAnalysisUpload = _doc
  ..constructionSafetyProgramUpload = _doc
  ..roadClearanceUpload = _doc
  ..unifiedApplicationFormUpload = _doc;

final _doc = DocumentModelStub.instance;

void main() {
  test('the checklist\'s lines are what block submission', () {
    expect(_complete().isValid, isTrue);
  });

  test('and the four the checklist does not list do not block it', () {
    // Tax declaration, real property tax receipt, bill of materials, barangay
    // clearance. All still have a slot — an evaluator may ask, and an
    // applicant who has one should be able to send it — but none of them
    // stops a filing.
    final documents = _complete();
    expect(documents.taxDeclarationUpload, isNull);
    expect(documents.realPropertyTaxReceiptUpload, isNull);
    expect(documents.billOfMaterialsUpload, isNull);
    expect(documents.barangayClearanceUpload, isNull);
    expect(documents.isValid, isTrue);
  });

  test('the applicant-and-owner ID is required, and used to have no slot', () {
    final documents = _complete()..validIdOfApplicantAndOwnerUpload = null;
    expect(
      documents.isValid,
      isFalse,
      reason:
          'the checklist asks for the ID of BOTH people on every application; '
          'the consent step only asks for the lot owner, and only when the '
          'applicant is not the owner',
    );
  });

  test('proof of ownership is not specifically a land title', () {
    // The checklist prints "Certified True Copy of OCT/TCT" with indented
    // alternatives — deed of sale, deed of donation, lease contract,
    // assignment of rights, "or any valid proof of ownership". The app
    // demanded a title, so an applicant building on leased land could not
    // file at all.
    final step = File(_step).readAsStringSync();
    expect(step, contains("label: 'Proof of ownership'"));
    expect(step, contains('deed of sale'));
    expect(step, contains('lease contract'));
    expect(
      step,
      isNot(contains("label: 'Land Title'")),
      reason:
          'the label named one of the accepted documents as if it were the '
          'only one',
    );
  });

  test('the four unlisted ones say why they are optional', () {
    final step = File(_step).readAsStringSync();
    expect(
      RegExp('not on the office’s checklist').allMatches(step).length,
      3,
      reason:
          'the tax receipt, the bill of materials and the barangay clearance. '
          'The tax declaration says something more useful — that it can serve '
          'as the proof of ownership',
    );
    expect(step, contains('or use it as your proof of ownership'));
  });

  test('the field kept its name so drafts still restore', () {
    // `landTitleUpload` now holds whatever proves ownership. The name is
    // wrong-ish and the storage key is right, which is the trade this
    // repository has settled on: a snapshot key is a compatibility surface.
    final model = File(
      'lib/core/models/building_permit_model.dart',
    ).readAsStringSync();
    expect(model, contains('DocumentModel? landTitleUpload;'));
    expect(
      model,
      contains('keeps its name so drafts saved before today still restore'),
    );
  });
}

/// A stand-in attachment. What is asserted here is which slots block a
/// filing, not what is in them.
class DocumentModelStub {
  static final instance = DocumentModel(
    id: 'stub',
    label: 'stub',
    fileName: 'stub.pdf',
    uploadedAt: DateTime(2026, 8, 31),
  );
}
