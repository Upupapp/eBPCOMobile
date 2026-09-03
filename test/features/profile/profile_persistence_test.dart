import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/repositories/auth_repository.dart';
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
      address: '24 Rizal Street',
      province: 'Sorsogon',
      city: 'Castilla',
      barangay: 'Bagalayag',
      zipCode: '4713',
    );

    expect(await storage.getRegisteredAddress(), '24 Rizal Street');
    expect(await storage.getRegisteredProvince(), 'Sorsogon');
    expect(await storage.getRegisteredCity(), 'Castilla');
    expect(await storage.getRegisteredBarangay(), 'Bagalayag');
    expect(await storage.getRegisteredZipCode(), '4713');
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
      address: '24 Rizal Street',
      barangay: 'Bagalayag',
    );

    // A fresh service and a fresh repository, as on a cold start.
    final user = await MockAuthRepository(
      storageService: LocalStorageService(),
    ).hydrateUser('juan@example.com');

    expect(user, isNotNull);
    expect(user!.address, '24 Rizal Street');
    expect(user.barangay, 'Bagalayag');
  });
}
