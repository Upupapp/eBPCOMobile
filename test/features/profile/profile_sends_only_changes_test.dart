import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/user_model.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/repositories/auth_repository.dart';

/// A save sends what moved, and nothing else.
///
/// Raised by the citizen web portal lane, which shipped `PATCH /me` first.
/// Echoing the whole profile back overwrites a field a second device altered
/// with the value this screen loaded before that happened — a lost update the
/// citizen never sees. It also sends a clear for a field that was already
/// null, which turns every save into a write.
///
/// The screen shows every field, so "the citizen emptied this box" and "this
/// box was already empty" look identical unless the record is consulted.

const _seed = UserModel(
  firstName: 'Juan',
  middleName: 'Santos',
  lastName: 'dela Cruz',
  email: 'juan@example.ph',
  mobileNumber: '09171234567',
  street: '24 Rizal Street',
  barangay: 'Bagalayag',
  city: 'Castilla',
  province: 'Sorsogon',
  postalCode: '4713',
);

class _Recording implements AuthRepository {
  final Map<String, FieldEdit> sent = {};

  @override
  Future<ProfileUpdate> updateProfile({
    FieldEdit firstName = const FieldEdit.absent(),
    FieldEdit middleName = const FieldEdit.absent(),
    FieldEdit lastName = const FieldEdit.absent(),
    FieldEdit mobileNumber = const FieldEdit.absent(),
    FieldEdit street = const FieldEdit.absent(),
    FieldEdit barangay = const FieldEdit.absent(),
    FieldEdit city = const FieldEdit.absent(),
    FieldEdit province = const FieldEdit.absent(),
    FieldEdit postalCode = const FieldEdit.absent(),
  }) async {
    sent
      ..clear()
      ..addAll({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'mobileNumber': mobileNumber,
        'street': street,
        'barangay': barangay,
        'city': city,
        'province': province,
        'postalCode': postalCode,
      });
    return const ProfileUpdate(user: _seed);
  }

  /// What a body built from these edits would actually carry.
  Set<String> get wireKeys => {
    for (final e in sent.entries)
      if (e.value.isPresent) e.key,
  };

  @override
  Future<UserModel?> authenticate({
    required String email,
    required String password,
  }) async => _seed;

  @override
  Future<bool> registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async => true;

  @override
  Future<UserModel?> hydrateUser(String email) async => _seed;

  @override
  Future<void> deleteAccount() async {}
}

Future<AuthProvider> _signedIn(_Recording repository) async {
  SharedPreferences.setMockInitialValues({});
  final provider = AuthProvider(
    authRepository: repository,
    storageService: null,
  );
  await provider.login(
    email: 'juan@example.ph',
    password: 'x',
    rememberMe: false,
  );
  return provider;
}

void main() {
  test('only the field that moved is sent', () async {
    final repository = _Recording();
    final provider = await _signedIn(repository);

    await provider.updateProfile(
      firstName: 'Juan',
      middleName: 'Santos',
      lastName: 'dela Cruz',
      mobileNumber: '09171234567',
      street: '99 Mabini Street',
      barangay: 'Bagalayag',
      city: 'Castilla',
      province: 'Sorsogon',
      postalCode: '4713',
    );

    expect(repository.wireKeys, {
      'street',
    }, reason: 'the rest are unchanged and must not overwrite another device');
  });

  test('a field already empty is not cleared again', () async {
    // Sending a clear for something already null makes every save a write.
    final repository = _Recording();
    final provider = await _signedIn(repository);

    await provider.updateProfile(
      firstName: 'Juan',
      middleName: 'Santos',
      lastName: 'dela Cruz',
      mobileNumber: '09171234567',
      street: '24 Rizal Street',
      barangay: 'Bagalayag',
      city: 'Castilla',
      province: 'Sorsogon',
      postalCode: '4713',
    );

    expect(repository.wireKeys, isEmpty, reason: 'nothing moved');
  });

  test('emptying a box still clears it', () async {
    // The half that must survive the optimisation: a citizen removing a middle
    // name they do not have still sends an explicit null.
    final repository = _Recording();
    final provider = await _signedIn(repository);

    await provider.updateProfile(
      firstName: 'Juan',
      middleName: '',
      lastName: 'dela Cruz',
      mobileNumber: '09171234567',
      street: '24 Rizal Street',
      barangay: 'Bagalayag',
      city: 'Castilla',
      province: 'Sorsogon',
      postalCode: '4713',
    );

    expect(repository.wireKeys, {'middleName'});
    expect(repository.sent['middleName']!.value, isNull);
  });
}
