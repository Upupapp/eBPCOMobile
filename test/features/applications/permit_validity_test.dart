import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';

/// Two deadlines sit on an issued permit, and they are not the same deadline.
///
/// **Commencement** is PD 1096's rule that authorised work must start within a
/// year or the permit is void. One year, every permit type. Already modelled
/// and correct.
///
/// **Validity** is how long the permit itself lasts, which the requirements
/// catalog gives per type: six months, twelve, or none at all for a
/// Certificate of Occupancy. Mobile had no notion of it, so an applicant with
/// a six-month permit was shown a date twelve months out and nothing else.

ApplicationModel _issued({
  required CanonicalPermitType type,
  DateTime? issuedDate,
}) => ApplicationModel(
  id: 'app-1',
  applicationNumber: 'E-BPCO-2026-000145',
  businessId: 'biz-1',
  businessName: 'Dela Cruz Construction',
  type: ApplicationType.newPermit,
  status: ApplicationStatus.released,
  submittedDate: DateTime(2026, 1, 1),
  lifecycleStatus: ApplicationLifecycleStatus.released,
  permitTypeLabel: type.wire,
  permitNumber: 'BP-2026-000145',
  issuedDate: issuedDate ?? DateTime(2026, 3, 1),
);

void main() {
  group('validity comes from the catalog', () {
    test('a Building Permit lasts twelve months', () {
      final application = _issued(
        type: CanonicalPermitType.buildingPermitNewConstruction,
      );
      expect(application.validityMonths, 12);
      expect(application.expiryDate, DateTime(2027, 3, 1));
    });

    test('a Fencing Permit lasts six', () {
      final application = _issued(type: CanonicalPermitType.fencingPermit);
      expect(application.validityMonths, 6);
      expect(application.expiryDate, DateTime(2026, 9, 1));
    });

    test('a Certificate of Occupancy never expires', () {
      final application = _issued(
        type: CanonicalPermitType.certificateOfOccupancy,
      );
      expect(application.validityMonths, isNull);
      expect(application.expiryDate, isNull);
      expect(application.daysUntilExpiry(DateTime(2030, 1, 1)), isNull);
      expect(application.expiryApproaching(DateTime(2030, 1, 1)), isFalse);
    });
  });

  group('validity is not commencement', () {
    test('a six-month permit expires before it must be commenced', () {
      // The case that makes conflating them wrong. Showing the commencement
      // date as an expiry would tell this applicant they had twice as long as
      // they do.
      final application = _issued(type: CanonicalPermitType.fencingPermit);

      expect(application.expiryDate, DateTime(2026, 9, 1));
      expect(application.commenceByDate, DateTime(2027, 3, 1));
      expect(
        application.expiryDate!.isBefore(application.commenceByDate!),
        isTrue,
        reason: 'validity runs out first, so it is the date that matters',
      );
    });

    test('a twelve-month permit has both on the same day, and still two', () {
      final application = _issued(type: CanonicalPermitType.electricalPermit);
      expect(application.expiryDate, application.commenceByDate);
      // Same date, different rules — one is about the permit lapsing, the
      // other about work not starting. They coincide here by arithmetic, not
      // because they are the same thing.
      expect(application.validityMonths, 12);
    });
  });

  group('warning', () {
    test('fires inside the shared threshold', () {
      final application = _issued(type: CanonicalPermitType.fencingPermit);
      // Expires 1 Sep 2026; 60 days before is 3 July.
      expect(application.expiryApproaching(DateTime(2026, 8, 15)), isTrue);
      expect(application.expiryApproaching(DateTime(2026, 5, 1)), isFalse);
    });

    test('uses the same threshold as the commencement warning', () {
      // Two deadlines on one permit warned at different distances would read
      // as arbitrary.
      expect(ApplicationModel.commencementWarningDays, 60);
    });
  });

  test('an unissued application has no expiry', () {
    final application = ApplicationModel(
      id: 'app-2',
      applicationNumber: 'E-BPCO-2026-000146',
      businessId: 'biz-1',
      businessName: 'Dela Cruz Construction',
      type: ApplicationType.newPermit,
      status: ApplicationStatus.underReview,
      submittedDate: DateTime(2026, 1, 1),
      lifecycleStatus: ApplicationLifecycleStatus.underEvaluation,
      permitTypeLabel: CanonicalPermitType.fencingPermit.wire,
    );
    expect(application.expiryDate, isNull);
  });
}
