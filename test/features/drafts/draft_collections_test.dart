import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/drafts/architectural_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/certificate_of_occupancy_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/demolition_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/draft_persistence_barrel.dart';
import 'package:ebpco_user_app/core/drafts/plumbing_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/sanitary_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/models/architectural_permit_model.dart';
import 'package:ebpco_user_app/core/models/certificate_of_occupancy_model.dart';
import 'package:ebpco_user_app/core/models/demolition_permit_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/plumbing_permit_model.dart';
import 'package:ebpco_user_app/core/models/sanitary_plumbing_permit_model.dart';

/// The six collection fields, which neither generic gate can see inside.
///
/// The completeness gate walks the draft's object graph, and a `Map` or a
/// `List` is a leaf to it: it can prove `installationDetails.fixtureInventory.
/// fixtures` is captured and read back, and nothing at all about the five
/// fields inside each fixture. The all-wizards round trip has the same blind
/// spot — it mutates scalars, and a collection is not one.
///
/// So these six are asserted by hand, with the values an applicant would have
/// typed. They are also the only places in the nineteen drafts where an
/// attachment is held inside a repeated record rather than in a named slot,
/// which is the case a re-attach list is most likely to lose.

DocumentModel _picked(String label) => DocumentModel(
  id: label,
  label: label,
  fileName: '$label.pdf',
  uploadedAt: DateTime(2026, 8, 30),
  filePath: '/tmp/$label.pdf',
);

/// Capture, then restore into a fresh draft. The shape both gates trust.
T _roundTrip<T>(DraftCodec<T> codec, T draft, T fresh) {
  codec.apply(fresh, codec.snapshot(draft, step: 0));
  return fresh;
}

void main() {
  group('Architectural — two enum-to-enum maps', () {
    test('each facility keeps its own status', () {
      const codec = ArchitecturalPermitDraftCodec();
      final draft = ArchitecturalPermitDraft();
      draft.complianceDetails.accessibility[AccessibilityFacility.stairs] =
          AccessibilityFacilityStatus.existingAndCompliant;
      draft.complianceDetails.accessibility[AccessibilityFacility.walkways] =
          AccessibilityFacilityStatus.proposed;
      draft.complianceDetails.fireCode[FireCodeFeature.exitDoors] =
          FireCodeFeatureStatus.applicantDeclaredCompliant;

      final restored = _roundTrip(
        codec,
        draft,
        ArchitecturalPermitDraft(),
      ).complianceDetails;

      expect(
        restored.accessibility[AccessibilityFacility.stairs],
        AccessibilityFacilityStatus.existingAndCompliant,
      );
      expect(
        restored.accessibility[AccessibilityFacility.walkways],
        AccessibilityFacilityStatus.proposed,
      );
      expect(
        restored.accessibility[AccessibilityFacility.corridors],
        AccessibilityFacilityStatus.notApplicable,
        reason: 'untouched facilities keep the model default',
      );
      expect(
        restored.fireCode[FireCodeFeature.exitDoors],
        FireCodeFeatureStatus.applicantDeclaredCompliant,
      );
      expect(
        restored.accessibility,
        hasLength(AccessibilityFacility.values.length),
      );
    });

    test('the two maps do not bleed into each other', () {
      // Both are Map<enum, enum> on the same object, captured through the same
      // helper. A copied block pointing at the wrong path would restore one
      // map's answers into the other, and nothing else would notice.
      const codec = ArchitecturalPermitDraftCodec();
      final draft = ArchitecturalPermitDraft();
      draft.complianceDetails.fireCode[FireCodeFeature.exitDoors] =
          FireCodeFeatureStatus.proposed;

      final restored = _roundTrip(
        codec,
        draft,
        ArchitecturalPermitDraft(),
      ).complianceDetails;
      expect(
        restored.accessibility.values.toSet(),
        {AccessibilityFacilityStatus.notApplicable},
        reason: 'nothing was set on accessibility, so nothing may appear there',
      );
      expect(
        restored.fireCode[FireCodeFeature.exitDoors],
        FireCodeFeatureStatus.proposed,
      );
    });
  });

  group('Demolition — a record per utility, each with its own proof', () {
    test('every field of a disconnection survives', () {
      const codec = DemolitionPermitDraftCodec();
      final draft = DemolitionPermitDraft();
      final electricity =
          draft.safetyAndSitePrep.utilities[UtilityType.electricity]!
            ..status = UtilityDisconnectionStatus.disconnected
            ..provider = 'SORECO II'
            ..disconnectionDate = DateTime(2026, 9, 15)
            ..referenceNumber = 'DC-2026-0091'
            ..supportingDocument = _picked('soreco');
      expect(electricity.provider, 'SORECO II');

      final restored = _roundTrip(codec, draft, DemolitionPermitDraft());
      final after =
          restored.safetyAndSitePrep.utilities[UtilityType.electricity]!;
      expect(after.status, UtilityDisconnectionStatus.disconnected);
      expect(after.provider, 'SORECO II');
      expect(after.disconnectionDate, DateTime(2026, 9, 15));
      expect(after.referenceNumber, 'DC-2026-0091');
      expect(
        after.supportingDocument,
        isNull,
        reason: 'an attachment inside a record is dropped like any other',
      );
      expect(
        restored.safetyAndSitePrep.utilities[UtilityType.water]!.provider,
        '',
        reason: 'the untouched utilities stay untouched',
      );
    });

    test('the dropped proof is named with the utility it belonged to', () {
      // Five utilities each hold a "supporting document". Told to re-attach
      // "supporting document" five times, an applicant cannot act on it.
      const codec = DemolitionPermitDraftCodec();
      final draft = DemolitionPermitDraft();
      draft
          .safetyAndSitePrep
          .utilities[UtilityType.electricity]!
          .supportingDocument = _picked(
        'a',
      );
      draft.safetyAndSitePrep.utilities[UtilityType.water]!.supportingDocument =
          _picked('b');

      expect(codec.snapshot(draft, step: 0).detachedDocuments, [
        'Disconnection proof: Electricity',
        'Disconnection proof: Water',
      ]);
    });
  });

  group('Plumbing and Sanitary — the fixture inventories', () {
    test('a fixture is matched back by type, not by position', () {
      const codec = PlumbingPermitDraftCodec();
      final draft = PlumbingPermitDraft();
      final lavatory =
          draft.installationDetails.fixtureInventory.fixtures.firstWhere(
              (f) => f.type == PlumbingFixtureType.lavatory,
            )
            ..newQuantity = '4'
            ..existingQuantity = '1'
            ..notes = 'second floor';
      expect(lavatory.totalQty, 5);

      final restored = _roundTrip(codec, draft, PlumbingPermitDraft());
      final after = restored.installationDetails.fixtureInventory.fixtures
          .firstWhere((f) => f.type == PlumbingFixtureType.lavatory);
      expect(after.newQuantity, '4');
      expect(after.existingQuantity, '1');
      expect(after.notes, 'second floor');
      expect(after.totalQty, 5);
      expect(
        restored.installationDetails.fixtureInventory.fixtures
            .where((f) => f.newQuantity.isNotEmpty)
            .map((f) => f.type),
        [PlumbingFixtureType.lavatory],
        reason: 'exactly one fixture was filled, so exactly one may come back',
      );
    });

    test('the sanitary inventory does the same', () {
      const codec = SanitaryPermitDraftCodec();
      final draft = SanitaryPermitDraft();
      draft.installationDetails.fixtureInventory.fixtures
              .firstWhere((f) => f.type == SanitaryFixtureType.waterCloset)
              .newQuantity =
          '2';

      final after = _roundTrip(codec, draft, SanitaryPermitDraft())
          .installationDetails
          .fixtureInventory
          .fixtures
          .firstWhere((f) => f.type == SanitaryFixtureType.waterCloset);
      expect(after.newQuantity, '2');
    });
  });

  group('Certificate of Occupancy — the one growable collection', () {
    test(
      'rows the applicant added come back, in order, without their files',
      () {
        const codec = CertificateOfOccupancyDraftCodec();
        final draft = CertificateOfOccupancyDraft();
        draft.requiredDocuments.otherDocuments.addAll([
          OccupancyOtherDocument(
            name: 'Sworn statement',
            description: 'notarised',
          )..file = _picked('sworn'),
          OccupancyOtherDocument(name: 'HOA clearance', description: ''),
        ]);

        final snapshot = codec.snapshot(draft, step: 0);
        expect(snapshot.detachedDocuments, [
          'Sworn statement',
        ], reason: "named by the applicant's own name for it");

        final restored = CertificateOfOccupancyDraft();
        codec.apply(restored, snapshot);
        final others = restored.requiredDocuments.otherDocuments;
        expect(others.map((d) => d.name), ['Sworn statement', 'HOA clearance']);
        expect(others.first.description, 'notarised');
        expect(others.every((d) => d.file == null), isTrue);
      },
    );

    test('restoring twice does not duplicate the rows', () {
      // The list is growable and the restore adds to it. Applying a snapshot
      // to a draft that already holds rows must replace them, not append —
      // otherwise a second restore doubles the applicant's list.
      const codec = CertificateOfOccupancyDraftCodec();
      final draft = CertificateOfOccupancyDraft();
      draft.requiredDocuments.otherDocuments.add(
        OccupancyOtherDocument(name: 'Sworn statement'),
      );
      final snapshot = codec.snapshot(draft, step: 0);

      final restored = CertificateOfOccupancyDraft();
      codec.apply(restored, snapshot);
      codec.apply(restored, snapshot);
      expect(restored.requiredDocuments.otherDocuments, hasLength(1));
    });

    test('an empty collection restores empty', () {
      const codec = CertificateOfOccupancyDraftCodec();
      final restored = CertificateOfOccupancyDraft();
      codec.apply(
        restored,
        codec.snapshot(CertificateOfOccupancyDraft(), step: 0),
      );
      expect(restored.requiredDocuments.otherDocuments, isEmpty);
    });
  });
}
