import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/action_item.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';

/// The Home action stack warned about one of the two deadlines a released
/// permit carries. A Fencing Permit's validity ends six months after issue and
/// its commencement deadline twelve — so an applicant six months in was told
/// nothing, while the permit they held had already lapsed.

ApplicationModel _released({
  required CanonicalPermitType type,
  required DateTime issuedDate,
}) => ApplicationModel(
  id: 'app-1',
  applicationNumber: 'E-BPCO-2026-000145',
  businessId: 'biz-1',
  businessName: 'Dela Cruz Construction',
  type: ApplicationType.newPermit,
  status: ApplicationStatus.released,
  submittedDate: DateTime(2026, 1, 5),
  lifecycleStatus: ApplicationLifecycleStatus.released,
  permitTypeLabel: type.wire,
  permitNumber: 'BP-2026-000145',
  issuedDate: issuedDate,
);

void main() {
  const builder = ActionItemBuilder();
  final asOf = DateTime(2026, 8, 18);

  test('a six-month permit is flagged for expiry before commencement is', () {
    final items = builder.build([
      _released(
        type: CanonicalPermitType.fencingPermit,
        issuedDate: DateTime(2026, 4, 1),
      ),
    ], asOf: asOf);

    // Issued 1 Apr 2026, so valid to 1 Oct 2026 — 44 days from asOf — while
    // commencement is not due until 1 Apr 2027 and raises nothing.
    expect(items.map((i) => i.kind), [ActionItemKind.expiryWarning]);
    expect(items.single.detail, contains('44 day'));
    expect(items.single.isCritical, isTrue);
  });

  test('an expired permit says so and asks for renewal', () {
    final items = builder.build([
      _released(
        type: CanonicalPermitType.fencingPermit,
        issuedDate: DateTime(2025, 10, 1),
      ),
    ], asOf: asOf);

    final expiry = items.firstWhere(
      (i) => i.kind == ActionItemKind.expiryWarning,
    );
    expect(expiry.title, 'Permit has expired');
    expect(expiry.detail, contains('Renewal'));
  });

  test('both deadlines raise their own item when both are near', () {
    // A twelve-month permit issued 1 Sep 2025: validity and commencement both
    // fall on 1 Sep 2026, 14 days out. Two obligations, two items — the
    // applicant's remedy differs (renew, versus start the work).
    final items = builder.build([
      _released(
        type: CanonicalPermitType.buildingPermitNewConstruction,
        issuedDate: DateTime(2025, 9, 1),
      ),
    ], asOf: asOf);

    expect(items.map((i) => i.kind).toSet(), {
      ActionItemKind.commencementWarning,
      ActionItemKind.expiryWarning,
    });
  });

  test('a Certificate of Occupancy is never flagged for expiry', () {
    final items = builder.build([
      _released(
        type: CanonicalPermitType.certificateOfOccupancy,
        issuedDate: DateTime(2025, 9, 1),
      ),
    ], asOf: asOf);

    expect(
      items.map((i) => i.kind),
      isNot(contains(ActionItemKind.expiryWarning)),
    );
    // Commencement still applies to the work it certifies.
    expect(
      items.map((i) => i.kind),
      contains(ActionItemKind.commencementWarning),
    );
  });
}
