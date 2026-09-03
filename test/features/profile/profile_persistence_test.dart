import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/user_model.dart';
import 'package:ebpco_user_app/core/repositories/auth_repository.dart';
import 'package:ebpco_user_app/core/utils/validators.dart';
import 'package:ebpco_user_app/core/services/local_storage_service.dart';

/// A profile the citizen edits has to survive closing the app.
///
/// `updateProfile` wrote first name, last name and mobile number and dropped
/// the rest. The screen collected an address, province, city, barangay and zip
/// code, said "Profile updated successfully", and lost all of them on the next
/// launch — the address being the one a notice would be posted to.
///
/// Separately and still true: none of this reaches the office. There is no
/// profile-update endpoint on the contract, so the LGU's record is unchanged
/// by anything done here. The screen now says so.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every field the screen collects is kept, not just three', () async {
    final storage = LocalStorageService();
    await storage.updateRegisteredProfile(
      firstName: 'Juan',
      lastName: 'dela Cruz',
      mobileNumber: '09171234567',
      middleName: 'Reyes',
      street: '24 Rizal Street',
      province: 'Sorsogon',
      city: 'Castilla',
      barangay: 'Bagalayag',
      postalCode: '4713',
    );

    expect(await storage.getRegisteredStreet(), '24 Rizal Street');
    expect(await storage.getRegisteredProvince(), 'Sorsogon');
    expect(await storage.getRegisteredCity(), 'Castilla');
    expect(await storage.getRegisteredBarangay(), 'Bagalayag');
    expect(await storage.getRegisteredPostalCode(), '4713');
    expect(await storage.getRegisteredMiddleName(), 'Reyes');
  });

  test('a new address is still there after a restart', () async {
    SharedPreferences.setMockInitialValues({
      'registeredEmail': 'juan@example.com',
    });
    // The restart is the point. Everything below the mobile number used to be
    // session-only, so the app agreed with the citizen until they closed it.
    final storage = LocalStorageService();
    await storage.updateRegisteredProfile(
      firstName: 'Juan',
      lastName: 'dela Cruz',
      mobileNumber: '09171234567',
      street: '24 Rizal Street',
      barangay: 'Bagalayag',
    );

    // A fresh service and a fresh repository, as on a cold start.
    final user = await MockAuthRepository(
      storageService: LocalStorageService(),
    ).hydrateUser('juan@example.com');

    expect(user, isNotNull);
    expect(user!.street, '24 Rizal Street');
    expect(user.barangay, 'Bagalayag');
  });

  group('a postal code the office can post to', () {
    // `PATCH /me` answers 400 on anything but four digits. An address the
    // office cannot post to is worse than none, because it gets acted on.
    test('four digits passes', () {
      expect(Validators.optionalPostalCode('4713'), isNull);
    });

    test('blank passes, because the citizen may have none recorded', () {
      expect(Validators.optionalPostalCode(''), isNull);
      expect(Validators.optionalPostalCode('   '), isNull);
    });

    test('anything else is refused before it reaches the office', () {
      expect(Validators.optionalPostalCode('471'), isNotNull);
      expect(Validators.optionalPostalCode('47133'), isNotNull);
      expect(Validators.optionalPostalCode('4A13'), isNotNull);
    });
  });

  group('null is not blank', () {
    test('an account never asked has no recorded address', () {
      const user = UserModel(
        firstName: 'Juan',
        lastName: 'dela Cruz',
        email: 'j@e.ph',
      );
      expect(user.street, isNull);
      expect(user.postalCode, isNull);
      expect(user.fullAddress, isEmpty);
      expect(
        user.hasNoRecordedAddress,
        isTrue,
        reason: 'nobody was ever asked, which is not the same as left blank',
      );
    });

    test('a partial address still reads as recorded', () {
      const user = UserModel(
        firstName: 'Juan',
        lastName: 'dela Cruz',
        email: 'j@e.ph',
        barangay: 'Bagalayag',
      );
      expect(user.fullAddress, 'Bagalayag');
      expect(user.hasNoRecordedAddress, isFalse);
    });
  });
}
