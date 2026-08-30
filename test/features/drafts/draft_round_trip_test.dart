import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/drafts/building_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/drafts/draft_persistence_barrel.dart';
import 'package:ebpco_user_app/core/drafts/fencing_permit_draft_codec.dart';
import 'package:ebpco_user_app/core/models/building_permit_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/fencing_permit_model.dart';
import 'package:ebpco_user_app/core/providers/building_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/fencing_permit_provider.dart';

/// M-48, end to end: what an applicant actually keeps when the app is killed.
///
/// The completeness gate proves every field is *named* in the codec. This
/// proves the values survive a real encode, a real store and a real decode —
/// which is a different claim, and the one the applicant cares about.
///
/// The store is the in-memory one, which round-trips through JSON exactly as
/// the keychain store does, so a value that does not serialise fails here
/// rather than on a device.

DocumentModel _picked(String label) => DocumentModel(
  id: label,
  label: label,
  fileName: '$label.pdf',
  uploadedAt: DateTime(2026, 8, 30),
  filePath: '/tmp/$label.pdf',
);

void main() {
  late DraftPersistence persistence;

  setUp(() => persistence = DraftPersistence(InMemoryDraftStore()));

  group('Building Permit', () {
    test('the typing survives a restart', () async {
      final before = BuildingPermitProvider(persistence: persistence);
      final draft = before.startNew();
      draft.applicant
        ..firstName = 'Maria'
        ..lastName = 'Dela Cruz'
        ..tin = '123-456-789'
        ..isOwnedByEnterprise = true
        ..enterpriseName = 'Dela Cruz Hardware'
        ..formOfOwnership = 'Sole Proprietorship';
      draft.constructionLocation
        ..lotNumber = '12'
        ..street = 'Rizal Street'
        ..barangay = 'Poblacion'
        ..city = 'Castilla';
      draft.buildingDetails
        ..totalFloorArea = '148.5'
        ..proposedConstructionDate = DateTime(2026, 10, 1);
      draft.projectInformation
        ..scopeOfWork = {ScopeOfWorkOption.others}
        ..occupancyGroup = OccupancyGroup.values.first;
      draft.professional.profession = ProfessionType.civilEngineer;
      draft.consentAuthorization.isRegisteredOwner = false;
      draft.reviewDeclaration.certifiesTrueAndCorrect = true;
      before.goToStep(4);
      before.saveAsDraft();
      await before.pendingWrite;

      // The process dies. Nothing of the provider survives.
      final after = BuildingPermitProvider(persistence: persistence);
      expect(await after.restoreFromStore(), isTrue);

      final restored = after.draft!;
      expect(restored.applicant.firstName, 'Maria');
      expect(restored.applicant.lastName, 'Dela Cruz');
      expect(restored.applicant.tin, '123-456-789');
      expect(restored.applicant.isOwnedByEnterprise, isTrue);
      expect(restored.applicant.enterpriseName, 'Dela Cruz Hardware');
      expect(restored.applicant.formOfOwnership, 'Sole Proprietorship');
      expect(restored.constructionLocation.lotNumber, '12');
      expect(restored.constructionLocation.street, 'Rizal Street');
      expect(restored.constructionLocation.city, 'Castilla');
      expect(restored.buildingDetails.totalFloorArea, '148.5');
      expect(
        restored.buildingDetails.proposedConstructionDate,
        DateTime(2026, 10, 1),
      );
      expect(restored.projectInformation.scopeOfWork, {
        ScopeOfWorkOption.others,
      });
      expect(restored.professional.profession, ProfessionType.civilEngineer);
      expect(restored.consentAuthorization.isRegisteredOwner, isFalse);
      expect(restored.reviewDeclaration.certifiesTrueAndCorrect, isTrue);
      expect(after.currentStep, 4, reason: 'resumes where they stopped');
      expect(after.hasResumableDraft, isTrue);
    });

    test('a cleared field stays cleared, rather than reverting', () async {
      // The case a "skip empty values" optimisation would break: a default of
      // true, deliberately turned off, must not come back on.
      final before = BuildingPermitProvider(persistence: persistence);
      final draft = before.startNew();
      draft.projectInformation.scopeOfWork = {};
      draft.applicant.firstName = '';
      before.saveAsDraft();
      await before.pendingWrite;

      final after = BuildingPermitProvider(persistence: persistence);
      await after.restoreFromStore();
      expect(after.draft!.projectInformation.scopeOfWork, isEmpty);
      expect(after.draft!.applicant.firstName, '');
    });

    test('attachments are dropped and named back to the applicant', () async {
      final before = BuildingPermitProvider(persistence: persistence);
      final draft = before.startNew();
      draft.requiredDocuments
        ..landTitleUpload = _picked('land-title')
        ..plansUpload = _picked('plans');
      draft.professional.prcIdUpload = _picked('prc');
      before.saveAsDraft();
      await before.pendingWrite;

      final after = BuildingPermitProvider(persistence: persistence);
      await after.restoreFromStore();

      expect(after.draft!.requiredDocuments.landTitleUpload, isNull);
      expect(after.draft!.requiredDocuments.plansUpload, isNull);
      expect(after.draft!.professional.prcIdUpload, isNull);
      expect(after.documentsToReattach, [
        'PRC ID of the professional in charge',
        'Land Title',
        'Plans',
      ]);
      expect(
        after.draftSummary!.documentsToReattach,
        hasLength(3),
        reason: 'the Drafts list is where the applicant is told',
      );
    });

    test('no attachment means no prompt', () async {
      final before = BuildingPermitProvider(persistence: persistence)
        ..startNew()
        ..saveAsDraft();
      await before.pendingWrite;

      final after = BuildingPermitProvider(persistence: persistence);
      await after.restoreFromStore();
      expect(after.documentsToReattach, isEmpty);
      expect(after.draftSummary!.documentsToReattach, isEmpty);
    });

    test('a submitted application does not come back as a draft', () async {
      final before = BuildingPermitProvider(persistence: persistence);
      before.startNew().applicant.firstName = 'Maria';
      before.saveAsDraft();
      await before.pendingWrite;
      before.submitApplication();
      await before.pendingWrite;

      final after = BuildingPermitProvider(persistence: persistence);
      expect(
        await after.restoreFromStore(),
        isFalse,
        reason: 'a filed application resurrected as editable is a defect',
      );
      expect(after.draft, isNull);
    });

    test('a discarded draft is gone from disk too', () async {
      final before = BuildingPermitProvider(persistence: persistence);
      before.startNew().applicant.firstName = 'Maria';
      before.saveAsDraft();
      await before.pendingWrite;
      before.discardDraft();
      await before.pendingWrite;

      final after = BuildingPermitProvider(persistence: persistence);
      expect(await after.restoreFromStore(), isFalse);
    });

    test('restoring never overwrites what the applicant is typing', () async {
      // The race the wizard can lose: a keychain read is fast, not instant,
      // and an applicant can reach step 1 before it lands.
      final seeded = BuildingPermitProvider(persistence: persistence);
      seeded.startNew().applicant.firstName = 'Last week';
      seeded.saveAsDraft();
      await seeded.pendingWrite;

      final relaunched = BuildingPermitProvider(persistence: persistence);
      relaunched.startNew().applicant.firstName = 'Typing now';
      expect(await relaunched.restoreFromStore(), isFalse);
      expect(relaunched.draft!.applicant.firstName, 'Typing now');
    });
  });

  group('Fencing Permit', () {
    test('sets, enums and both professionals survive', () async {
      final before = FencingPermitProvider(persistence: persistence);
      final draft = before.startNew();
      draft.relatedBuildingPermit
        ..buildingPermitNumber = 'BP-2026-100234'
        ..status = RelatedBuildingPermitStatus.approved;
      draft.scopeOfWork.selectedScopes.addAll({
        FencingScopeType.erection,
        FencingScopeType.repair,
      });
      draft.specifications
        ..fenceLengthMeters = '24'
        ..fenceHeightMeters = '2.4';
      draft.specifications.selectedTypes.add(FencingType.rcAndHollowBlocks);
      draft.professionals.designProfessional
        ..fullName = 'Engr. Santos'
        ..profession = FencingProfessionType.civilEngineer
        ..prcValidityDate = DateTime(2027, 3, 1);
      draft.professionals.supervisor
        ..fullName = 'Arch. Reyes'
        ..profession = FencingProfessionType.architect;
      draft.consent
        ..isApplicantAlsoLotOwner = false
        ..lotOwner.printedName = 'Lot Owner';
      before.saveAsDraft();
      await before.pendingWrite;

      final after = FencingPermitProvider(persistence: persistence);
      await after.restoreFromStore();
      final restored = after.draft!;

      expect(
        restored.relatedBuildingPermit.buildingPermitNumber,
        'BP-2026-100234',
      );
      expect(
        restored.relatedBuildingPermit.status,
        RelatedBuildingPermitStatus.approved,
      );
      expect(restored.scopeOfWork.selectedScopes, {
        FencingScopeType.erection,
        FencingScopeType.repair,
      });
      expect(restored.specifications.selectedTypes, {
        FencingType.rcAndHollowBlocks,
      });
      expect(restored.specifications.fenceHeightMeters, '2.4');
      // Two roles, one shape. A copy-paste that pointed the supervisor at the
      // design professional's prefix would show up right here.
      expect(
        restored.professionals.designProfessional.fullName,
        'Engr. Santos',
      );
      expect(
        restored.professionals.designProfessional.profession,
        FencingProfessionType.civilEngineer,
      );
      expect(
        restored.professionals.designProfessional.prcValidityDate,
        DateTime(2027, 3, 1),
      );
      expect(restored.professionals.supervisor.fullName, 'Arch. Reyes');
      expect(
        restored.professionals.supervisor.profession,
        FencingProfessionType.architect,
      );
      expect(restored.consent.isApplicantAlsoLotOwner, isFalse);
      expect(restored.consent.lotOwner.printedName, 'Lot Owner');
    });

    test('one wizard cannot overwrite another', () async {
      // Both drafts share a single keychain record. Two saves racing over one
      // map is how the second silently erases the first.
      final building = BuildingPermitProvider(persistence: persistence);
      final fencing = FencingPermitProvider(persistence: persistence);
      building.startNew().applicant.firstName = 'Building';
      fencing.startNew().applicant.firstName = 'Fencing';
      building.saveAsDraft();
      fencing.saveAsDraft();
      await Future.wait([building.pendingWrite, fencing.pendingWrite]);

      final b = BuildingPermitProvider(persistence: persistence);
      final f = FencingPermitProvider(persistence: persistence);
      await b.restoreFromStore();
      await f.restoreFromStore();
      expect(b.draft!.applicant.firstName, 'Building');
      expect(f.draft!.applicant.firstName, 'Fencing');
    });
  });

  group('the store itself', () {
    test('an enum is stored by name, so reordering cannot shift it', () {
      final draft = FencingPermitDraft()
        ..relatedBuildingPermit.status = RelatedBuildingPermitStatus.approved;
      final snapshot = const FencingPermitDraftCodec().snapshot(draft, step: 0);
      expect(snapshot.fields['relatedBuildingPermit.status'], 'approved');
    });

    test('an unknown enum name is dropped, not fatal', () {
      // A value renamed between releases. The applicant loses that one field,
      // never the other seventy.
      final snapshot = DraftSnapshot(
        permitKey: 'building-permit',
        step: 0,
        savedAt: DateTime(2026, 8, 30),
        fields: const {
          'applicant.firstName': 'Maria',
          'professional.profession': 'quantitySurveyor',
        },
      );
      final draft = BuildingPermitDraft();
      const BuildingPermitDraftCodec().apply(draft, snapshot);
      expect(draft.applicant.firstName, 'Maria');
      expect(draft.professional.profession, isNull);
    });

    test('a draft older than the retention window is dropped', () async {
      // Personal data with no end date is not minimisation under RA 10173.
      // Ninety days rather than the queue's thirty: an applicant waits on a
      // professional, a clearance and a notary, and a month untouched is the
      // normal shape of that task.
      final now = DateTime(2026, 8, 30);
      DraftSnapshot aged(String key, Duration ago) => DraftSnapshot(
        permitKey: key,
        step: 0,
        savedAt: now.subtract(ago),
        fields: const {'applicant.firstName': 'Maria'},
      );
      final raw = encodeDrafts({
        'building-permit': aged('building-permit', const Duration(days: 89)),
        'fencing-permit': aged('fencing-permit', const Duration(days: 91)),
      });

      final kept = decodeDrafts(raw, now: now);
      expect(kept.keys, ['building-permit']);
      expect(draftRetention, const Duration(days: 90));
    });

    test('one unreadable record does not take the others with it', () {
      // The failure that would otherwise cost an applicant every draft they
      // have: a single record written by a release whose shape has changed.
      final good = DraftSnapshot(
        permitKey: 'fencing-permit',
        step: 2,
        savedAt: DateTime(2026, 8, 30),
        fields: const {'applicant.firstName': 'Ana'},
      );
      final raw = jsonEncode({
        'building-permit': {
          'permitKey': 'building-permit',
          'savedAt': 'not a date',
          'fields': <String, Object?>{},
        },
        'fencing-permit': good.toJson(),
      });

      final kept = decodeDrafts(raw, now: DateTime(2026, 8, 30));
      expect(kept.keys, ['fencing-permit']);
      expect(kept['fencing-permit']!.step, 2);
    });

    test(
      'a store that is not JSON at all yields nothing, and does not throw',
      () {
        expect(
          decodeDrafts('}{ not json', now: DateTime(2026, 8, 30)),
          isEmpty,
        );
        expect(decodeDrafts('"a string"', now: DateTime(2026, 8, 30)), isEmpty);
        expect(decodeDrafts('', now: DateTime(2026, 8, 30)), isEmpty);
      },
    );

    test('a corrupt record does not take the others with it', () async {
      final snapshot = DraftSnapshot(
        permitKey: 'fencing-permit',
        step: 1,
        savedAt: DateTime(2026, 8, 30),
        fields: const {'applicant.firstName': 'Ana'},
      );
      expect(
        () => DraftSnapshot.fromJson({
          ...snapshot.toJson(),
          'savedAt': 'not a date',
        }),
        throwsFormatException,
      );
      expect(
        DraftSnapshot.fromJson(snapshot.toJson()).fields['applicant.firstName'],
        'Ana',
      );
    });
  });
}
