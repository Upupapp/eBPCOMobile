import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/drafts/building_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/draft_persistence_barrel.dart';
import 'package:ebpco_user_app/core/models/building_permit_model.dart';

/// The three gaps the Unified Application Form audit found, closed.
///
/// All on the permit most applicants file, and all invisible to every gate in
/// this repository, because every one of them compares the app against the
/// app. Only the paper says what the office actually asks for.

const _step4 =
    'lib/features/applications/presentation/building_permit/steps/'
    'step4_building_details.dart';
const _step6 =
    'lib/features/applications/presentation/building_permit/steps/'
    'step6_consent_authorization.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('NUMBER OF STOREY', () {
    test('is collected, and required like its neighbours', () {
      // The form asks for it beside Number of Units, Total Floor Area and Lot
      // Area — all three of which the app already required.
      final details = BuildingDetails()
        ..occupancyClassification = 'Residential'
        ..numberOfUnits = '1'
        ..totalFloorArea = '120'
        ..lotArea = '200'
        ..estimatedConstructionCost = '1500000'
        ..proposedConstructionDate = DateTime(2026, 10, 1)
        ..expectedCompletionDate = DateTime(2027, 4, 1);

      expect(
        details.isValid,
        isFalse,
        reason: 'the storey count is blank, and the form does not accept that',
      );
      details.numberOfStorey = '2';
      expect(details.isValid, isTrue);
    });

    test('and the wizard asks for it', () {
      expect(_read(_step4), contains("label: 'Number of Storeys *'"));
      expect(_read(_step4), contains('_details.numberOfStorey = v'));
    });
  });

  group('the estimated cost breakdown', () {
    test('all six lines the form prints exist', () {
      // TOTAL ESTIMATED COST, then Building · Electrical · Mechanical ·
      // Electronics · Plumbing, and Cost of Equipment Installed beside them.
      final details = BuildingDetails()
        ..estimatedCostBuilding = '900000'
        ..estimatedCostElectrical = '200000'
        ..estimatedCostMechanical = '150000'
        ..estimatedCostElectronics = '50000'
        ..estimatedCostPlumbing = '120000'
        ..costOfEquipmentInstalled = '80000';
      expect(details.estimatedCostBuilding, '900000');
      expect(details.costOfEquipmentInstalled, '80000');
    });

    test('they are optional — the form does not press them', () {
      // A simple residential permit may have nothing against electronics or
      // mechanical, and demanding a zero would ask a question the paper does
      // not ask.
      final details = BuildingDetails()
        ..occupancyClassification = 'Residential'
        ..numberOfUnits = '1'
        ..numberOfStorey = '1'
        ..totalFloorArea = '60'
        ..lotArea = '100'
        ..estimatedConstructionCost = '450000'
        ..proposedConstructionDate = DateTime(2026, 10, 1)
        ..expectedCompletionDate = DateTime(2027, 1, 1);
      expect(details.isValid, isTrue);
    });

    test('and the wizard renders all six', () {
      final step = _read(_step4);
      for (final label in const [
        'Cost — Building',
        'Cost — Electrical',
        'Cost — Mechanical',
        'Cost — Electronics',
        'Cost — Plumbing',
        'Cost of Equipment Installed',
      ]) {
        expect(step, contains("'$label'"), reason: label);
      }
    });
  });

  group('Boxes 3 and 4 ask for a government-issued ID, not a cedula', () {
    test('the model and the label both say so', () {
      final consent = ConsentAuthorization()
        ..governmentIdNumber = 'P1234567A'
        ..governmentIdPlaceIssued = 'DFA Legazpi';
      expect(consent.governmentIdNumber, 'P1234567A');
      expect(consent.governmentIdPlaceIssued, 'DFA Legazpi');

      final step = _read(_step6);
      expect(step, contains("label: 'Government-issued ID Number *'"));
      expect(
        step,
        isNot(contains("label: 'CTC Number *'")),
        reason: 'the building permit is the one form that does NOT ask for one',
      );
    });

    test('the ancillary permits still ask for a CTC, because they do', () {
      // Fencing, Civil/Structural, Electrical and the rest print C.T.C. No.
      // The fix must not spread to them.
      expect(
        _read('lib/core/models/fencing_permit_model.dart'),
        contains('ctcNumber'),
      );
    });
  });

  group('a draft saved before the rename still gives its answers back', () {
    // The storage key is a compatibility surface. Renaming a Dart field is
    // free; renaming a snapshot key silently loses whatever an applicant had
    // already typed, and drafts have persisted since M-48.
    const codec = BuildingPermitDraftCodec();

    test('the legacy keys are read as a fallback', () {
      final legacy = DraftSnapshot(
        permitKey: 'building-permit',
        step: 5,
        savedAt: DateTime(2026, 8, 30),
        fields: const {
          'consentAuthorization.ctcNumber': '07-1234567',
          'consentAuthorization.ctcDateIssued': '2026-01-15T00:00:00.000',
          'consentAuthorization.ctcPlaceIssued': 'Castilla',
        },
      );
      final draft = BuildingPermitDraft();
      codec.apply(draft, legacy);

      expect(draft.consentAuthorization.governmentIdNumber, '07-1234567');
      expect(
        draft.consentAuthorization.governmentIdDateIssued,
        DateTime(2026, 1, 15),
      );
      expect(draft.consentAuthorization.governmentIdPlaceIssued, 'Castilla');
    });

    test('and the new key wins when both are present', () {
      final both = DraftSnapshot(
        permitKey: 'building-permit',
        step: 5,
        savedAt: DateTime(2026, 8, 31),
        fields: const {
          'consentAuthorization.ctcNumber': 'old',
          'consentAuthorization.governmentIdNumber': 'new',
        },
      );
      final draft = BuildingPermitDraft();
      codec.apply(draft, both);
      expect(draft.consentAuthorization.governmentIdNumber, 'new');
    });

    test('the new fields round-trip', () {
      final draft = BuildingPermitDraft();
      draft.buildingDetails
        ..numberOfStorey = '3'
        ..estimatedCostElectrical = '200000'
        ..costOfEquipmentInstalled = '80000';
      final restored = BuildingPermitDraft();
      codec.apply(restored, codec.snapshot(draft, step: 3));
      expect(restored.buildingDetails.numberOfStorey, '3');
      expect(restored.buildingDetails.estimatedCostElectrical, '200000');
      expect(restored.buildingDetails.costOfEquipmentInstalled, '80000');
    });
  });
}
