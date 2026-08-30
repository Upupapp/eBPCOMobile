import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/shared/widgets/uploads/document_upload_tile.dart';
import 'package:ebpco_user_app/core/models/addition_extension_permit_model.dart'
    as m0;
import 'package:ebpco_user_app/core/models/architectural_permit_model.dart'
    as m1;
import 'package:ebpco_user_app/core/models/building_permit_model.dart' as m2;
import 'package:ebpco_user_app/core/models/certificate_of_occupancy_model.dart'
    as m3;
import 'package:ebpco_user_app/core/models/civil_structural_permit_model.dart'
    as m4;
import 'package:ebpco_user_app/core/models/demolition_permit_model.dart' as m5;
import 'package:ebpco_user_app/core/models/electrical_permit_model.dart' as m6;
import 'package:ebpco_user_app/core/models/electronics_permit_model.dart' as m7;
import 'package:ebpco_user_app/core/models/excavation_permit_model.dart' as m8;
import 'package:ebpco_user_app/core/models/fencing_permit_model.dart' as m9;
import 'package:ebpco_user_app/core/models/interior_design_permit_model.dart'
    as m10;
import 'package:ebpco_user_app/core/models/mechanical_permit_model.dart' as m11;
import 'package:ebpco_user_app/core/models/plumbing_permit_model.dart' as m12;
import 'package:ebpco_user_app/core/models/renovation_permit_model.dart' as m13;
import 'package:ebpco_user_app/core/models/sanitary_plumbing_permit_model.dart'
    as m14;
import 'package:ebpco_user_app/core/models/sign_permit_model.dart' as m15;
import 'package:ebpco_user_app/features/applications/presentation/addition_extension_permit/steps/step5_professional_in_charge.dart'
    as w0s0;
import 'package:ebpco_user_app/features/applications/presentation/addition_extension_permit/steps/step6_ownership_authorization.dart'
    as w0s1;
import 'package:ebpco_user_app/features/applications/presentation/addition_extension_permit/steps/step7_required_documents.dart'
    as w0s2;
import 'package:ebpco_user_app/features/applications/presentation/architectural_permit/steps/step5_professionals.dart'
    as w1s0;
import 'package:ebpco_user_app/features/applications/presentation/architectural_permit/steps/step6_ownership_consent.dart'
    as w1s1;
import 'package:ebpco_user_app/features/applications/presentation/architectural_permit/steps/step7_required_documents.dart'
    as w1s2;
import 'package:ebpco_user_app/features/applications/presentation/building_permit/steps/step5_professional_in_charge.dart'
    as w2s0;
import 'package:ebpco_user_app/features/applications/presentation/building_permit/steps/step6_consent_authorization.dart'
    as w2s1;
import 'package:ebpco_user_app/features/applications/presentation/building_permit/steps/step7_required_documents.dart'
    as w2s2;
import 'package:ebpco_user_app/features/applications/presentation/certificate_of_occupancy/steps/step4_required_documents.dart'
    as w3s0;
import 'package:ebpco_user_app/features/applications/presentation/certificate_of_occupancy/steps/step5_certification_review_submission.dart'
    as w3s1;
import 'package:ebpco_user_app/features/applications/presentation/civil_structural_permit/steps/step5_professionals.dart'
    as w4s0;
import 'package:ebpco_user_app/features/applications/presentation/civil_structural_permit/steps/step6_ownership_consent.dart'
    as w4s1;
import 'package:ebpco_user_app/features/applications/presentation/civil_structural_permit/steps/step7_required_documents.dart'
    as w4s2;
import 'package:ebpco_user_app/features/applications/presentation/demolition_permit/steps/step4_safety_site_prep.dart'
    as w5s0;
import 'package:ebpco_user_app/features/applications/presentation/demolition_permit/steps/step5_demolition_supervisor.dart'
    as w5s1;
import 'package:ebpco_user_app/features/applications/presentation/demolition_permit/steps/step6_ownership_consent.dart'
    as w5s2;
import 'package:ebpco_user_app/features/applications/presentation/demolition_permit/steps/step7_required_documents.dart'
    as w5s3;
import 'package:ebpco_user_app/features/applications/presentation/electrical_permit/steps/step5_professionals.dart'
    as w6s0;
import 'package:ebpco_user_app/features/applications/presentation/electrical_permit/steps/step6_ownership_consent.dart'
    as w6s1;
import 'package:ebpco_user_app/features/applications/presentation/electrical_permit/steps/step7_required_documents.dart'
    as w6s2;
import 'package:ebpco_user_app/features/applications/presentation/electronics_permit/steps/step5_professionals.dart'
    as w7s0;
import 'package:ebpco_user_app/features/applications/presentation/electronics_permit/steps/step6_ownership_consent.dart'
    as w7s1;
import 'package:ebpco_user_app/features/applications/presentation/electronics_permit/steps/step7_required_documents.dart'
    as w7s2;
import 'package:ebpco_user_app/features/applications/presentation/excavation_permit/steps/step7_design_professional.dart'
    as w8s0;
import 'package:ebpco_user_app/features/applications/presentation/excavation_permit/steps/step8_supervisor.dart'
    as w8s1;
import 'package:ebpco_user_app/features/applications/presentation/excavation_permit/steps/step9_consent_review_submission.dart'
    as w8s2;
import 'package:ebpco_user_app/features/applications/presentation/fencing_permit/steps/step5_design_professional.dart'
    as w9s0;
import 'package:ebpco_user_app/features/applications/presentation/fencing_permit/steps/step6_supervisor.dart'
    as w9s1;
import 'package:ebpco_user_app/features/applications/presentation/fencing_permit/steps/step7_consent.dart'
    as w9s2;
import 'package:ebpco_user_app/features/applications/presentation/interior_design_permit/steps/step5_professionals.dart'
    as w10s0;
import 'package:ebpco_user_app/features/applications/presentation/interior_design_permit/steps/step6_ownership_consent.dart'
    as w10s1;
import 'package:ebpco_user_app/features/applications/presentation/interior_design_permit/steps/step7_required_documents.dart'
    as w10s2;
import 'package:ebpco_user_app/features/applications/presentation/mechanical_permit/steps/step5_professionals.dart'
    as w11s0;
import 'package:ebpco_user_app/features/applications/presentation/mechanical_permit/steps/step6_ownership_consent.dart'
    as w11s1;
import 'package:ebpco_user_app/features/applications/presentation/mechanical_permit/steps/step7_required_documents.dart'
    as w11s2;
import 'package:ebpco_user_app/features/applications/presentation/plumbing_permit/steps/step5_professionals.dart'
    as w12s0;
import 'package:ebpco_user_app/features/applications/presentation/plumbing_permit/steps/step6_ownership_consent.dart'
    as w12s1;
import 'package:ebpco_user_app/features/applications/presentation/plumbing_permit/steps/step7_required_documents.dart'
    as w12s2;
import 'package:ebpco_user_app/features/applications/presentation/renovation_permit/steps/step5_professional_in_charge.dart'
    as w13s0;
import 'package:ebpco_user_app/features/applications/presentation/renovation_permit/steps/step6_ownership_authorization.dart'
    as w13s1;
import 'package:ebpco_user_app/features/applications/presentation/renovation_permit/steps/step7_renovation_documents.dart'
    as w13s2;
import 'package:ebpco_user_app/features/applications/presentation/sanitary_plumbing_permit/steps/step5_professionals.dart'
    as w14s0;
import 'package:ebpco_user_app/features/applications/presentation/sanitary_plumbing_permit/steps/step6_ownership_consent.dart'
    as w14s1;
import 'package:ebpco_user_app/features/applications/presentation/sanitary_plumbing_permit/steps/step7_required_documents.dart'
    as w14s2;
import 'package:ebpco_user_app/features/applications/presentation/sign_permit/steps/step6_required_documents.dart'
    as w15s0;
import 'package:ebpco_user_app/features/applications/presentation/sign_permit/steps/step7_design_professional.dart'
    as w15s1;
import 'package:ebpco_user_app/features/applications/presentation/sign_permit/steps/step8_supervisor.dart'
    as w15s2;
import 'package:ebpco_user_app/features/applications/presentation/sign_permit/steps/step9_consent.dart'
    as w15s3;
import 'package:ebpco_user_app/features/applications/presentation/fencing_permit/steps/step3_construction_location.dart'
    as w9s9;
import 'package:ebpco_user_app/features/applications/presentation/excavation_permit/steps/step3_construction_location.dart'
    as w8s9;
import 'package:ebpco_user_app/core/models/zoning_permit_model.dart' as mz;
import 'package:ebpco_user_app/features/applications/presentation/zoning_clearance/steps/step4_required_documents.dart'
    as wz;
import 'package:ebpco_user_app/core/models/fsec_permit_model.dart' as mfe;
import 'package:ebpco_user_app/core/models/fsic_permit_model.dart' as mfi;
import 'package:ebpco_user_app/features/applications/presentation/fsec_clearance/steps/step3_required_documents.dart'
    as wfe;
import 'package:ebpco_user_app/features/applications/presentation/fsic_clearance/steps/step3_required_documents.dart'
    as wfi;

/// How many documents each wizard actually asks an applicant to upload.
///
/// Counted by rendering every document-bearing step and counting the
/// `DocumentUploadTile`s in the tree. Three attempts to count this statically
/// produced three different wrong answers: grepping for `DocumentUploadTile(`
/// undercounts every wizard that wraps it in a helper — Building Permit read
/// as 5 and has 15 — and following helper call sites over-counts by picking up
/// unrelated `label:` arguments, reading Mechanical as 87.
///
/// Mounting the wizard itself does not work either: its `PageView` builds only
/// the visible page, so a freshly mounted wizard contains no upload tiles at
/// all. The steps have to be mounted one at a time.
///
/// These numbers exist so the reconciliation of each wizard against the
/// requirements catalog rests on something true, and so a slot that quietly
/// disappears is a failing test rather than a later discovery.

/// Slots on a fresh draft. Conditional ones that appear only after an answer —
/// Step 6's representative uploads, say — are not counted, because this is what
/// the applicant is asked for by default.
const _expected = <String, int>{
  'addition_extension_permit': 36,
  'architectural_permit': 29,
  // 22 until 31 August 2026. The checklist audit added the applicant-and-owner
  // ID the step had no slot for; four others became optional rather than being
  // removed, so they still render and still count.
  'building_permit': 23,
  // Still 13 after the 31 August rewrite against Castilla's own occupancy
  // checklist — six slots added and five removed happens to net out at the
  // same count, which is exactly why a census counts and does not compare
  // names. What changed is asserted by name in
  // `test/architecture/occupancy_requirements_test.dart`.
  'certificate_of_occupancy': 13,
  'zoning_clearance': 16,
  'fsec_clearance': 9,
  'fsic_clearance': 10,
  'civil_structural_permit': 61,
  'demolition_permit': 33,
  'electrical_permit': 51,
  'electronics_permit': 15,
  'excavation_permit': 8,
  'fencing_permit': 7,
  'interior_design_permit': 27,
  'mechanical_permit': 78,
  'plumbing_permit': 61,
  'renovation_permit': 30,
  'sanitary_plumbing_permit': 62,
  'sign_permit': 12,
};

final _wizards = <String, List<Widget Function()> Function()>{
  'fsec_clearance': () {
    final draft = mfe.FsecPermitDraft();
    return <Widget Function()>[
      () => wfe.Step3RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'fsic_clearance': () {
    final draft = mfi.FsicPermitDraft();
    return <Widget Function()>[
      () => wfi.Step3RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'zoning_clearance': () {
    final draft = mz.ZoningPermitDraft();
    return <Widget Function()>[
      () => wz.Step4RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'addition_extension_permit': () {
    final draft = m0.AdditionExtensionPermitDraft();
    return <Widget Function()>[
      () => w0s0.Step5ProfessionalInCharge(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w0s1.Step6OwnershipAuthorization(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w0s2.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'architectural_permit': () {
    final draft = m1.ArchitecturalPermitDraft();
    return <Widget Function()>[
      () => w1s0.Step5Professionals(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w1s1.Step6OwnershipConsent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w1s2.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'building_permit': () {
    final draft = m2.BuildingPermitDraft();
    return <Widget Function()>[
      () => w2s0.Step5ProfessionalInCharge(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w2s1.Step6ConsentAuthorization(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w2s2.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'certificate_of_occupancy': () {
    final draft = m3.CertificateOfOccupancyDraft();
    return <Widget Function()>[
      () => w3s0.Step4RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w3s1.Step5CertificationReviewSubmission(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
        onEditStep: (_) {},
      ),
    ];
  },
  'civil_structural_permit': () {
    final draft = m4.CivilStructuralPermitDraft();
    return <Widget Function()>[
      () => w4s0.Step5Professionals(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w4s1.Step6OwnershipConsent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w4s2.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'demolition_permit': () {
    final draft = m5.DemolitionPermitDraft();
    return <Widget Function()>[
      () => w5s0.Step4SafetySitePrep(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w5s1.Step5DemolitionSupervisor(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w5s2.Step6OwnershipConsent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w5s3.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'electrical_permit': () {
    final draft = m6.ElectricalPermitDraft();
    return <Widget Function()>[
      () => w6s0.Step5Professionals(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w6s1.Step6OwnershipConsent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w6s2.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'electronics_permit': () {
    final draft = m7.ElectronicsPermitDraft();
    return <Widget Function()>[
      () => w7s0.Step5Professionals(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w7s1.Step6OwnershipConsent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w7s2.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'excavation_permit': () {
    final draft = m8.ExcavationPermitDraft();
    return <Widget Function()>[
      () => w8s9.Step3ConstructionLocation(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w8s0.Step7DesignProfessional(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w8s1.Step8Supervisor(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w8s2.Step9ConsentReviewSubmission(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
        onEditStep: (_) {},
      ),
    ];
  },
  'fencing_permit': () {
    final draft = m9.FencingPermitDraft();
    return <Widget Function()>[
      () => w9s9.Step3ConstructionLocation(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w9s0.Step5DesignProfessional(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w9s1.Step6Supervisor(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w9s2.Step7Consent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'interior_design_permit': () {
    final draft = m10.InteriorPermitDraft();
    return <Widget Function()>[
      () => w10s0.Step5Professionals(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w10s1.Step6OwnershipConsent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w10s2.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'mechanical_permit': () {
    final draft = m11.MechanicalPermitDraft();
    return <Widget Function()>[
      () => w11s0.Step5Professionals(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w11s1.Step6OwnershipConsent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w11s2.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'plumbing_permit': () {
    final draft = m12.PlumbingPermitDraft();
    return <Widget Function()>[
      () => w12s0.Step5Professionals(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w12s1.Step6OwnershipConsent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w12s2.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'renovation_permit': () {
    final draft = m13.RenovationPermitDraft();
    return <Widget Function()>[
      () => w13s0.Step5ProfessionalInCharge(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w13s1.Step6OwnershipAuthorization(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w13s2.Step7RenovationDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'sanitary_plumbing_permit': () {
    final draft = m14.SanitaryPermitDraft();
    return <Widget Function()>[
      () => w14s0.Step5Professionals(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w14s1.Step6OwnershipConsent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w14s2.Step7RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
  'sign_permit': () {
    final draft = m15.SignPermitDraft();
    return <Widget Function()>[
      () => w15s0.Step6RequiredDocuments(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w15s1.Step7DesignProfessional(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w15s2.Step8Supervisor(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
      () => w15s3.Step9Consent(
        formKey: GlobalKey<FormState>(),
        draft: draft,
        onChanged: () {},
      ),
    ];
  },
};

Future<int> _countSlots(
  WidgetTester tester,
  List<Widget Function()> steps,
) async {
  var total = 0;
  for (final build in steps) {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SingleChildScrollView(child: build())),
      ),
    );
    await tester.pump();
    total += find
        .byType(DocumentUploadTile, skipOffstage: false)
        .evaluate()
        .length;
  }
  return total;
}

void main() {
  _wizards.forEach((name, steps) {
    testWidgets('$name offers its expected upload slots', (tester) async {
      tester.view.physicalSize = const Size(420, 8000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final count = await _countSlots(tester, steps());
      expect(
        count,
        _expected[name],
        reason:
            '$name renders $count upload slots, fixture says '
            '${_expected[name]}',
      );

      // Every slot is reachable on a fresh draft — measured, not assumed. If a
      // wizard grows a conditional upload that only appears after a selection,
      // these two diverge and this is where it shows.
      final visible = await _countVisible(tester, steps());
      expect(
        visible,
        count,
        reason: '$name hides ${count - visible} slots behind a condition',
      );
    });
  });
}

/// Slots an applicant can see and use straight away — nothing selected, no
/// section opened.
///
/// The difference between this and the offstage-inclusive count is the
/// wizard's conditional surface: equipment-specific uploads that appear once a
/// category is chosen, and tiles inside collapsed sections, which
/// `AnimatedCrossFade` keeps mounted rather than removing. Both numbers are
/// real and they answer different questions — "what am I asked for now" versus
/// "what can this wizard ever ask for".
Future<int> _countVisible(
  WidgetTester tester,
  List<Widget Function()> steps,
) async {
  var total = 0;
  for (final build in steps) {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SingleChildScrollView(child: build())),
      ),
    );
    await tester.pump();
    total += find.byType(DocumentUploadTile).evaluate().length;
  }
  return total;
}
