import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/business_model.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/user_model.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/business_provider.dart';
import 'package:ebpco_user_app/core/providers/documents_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/auth_repository.dart';
import 'package:ebpco_user_app/core/repositories/business_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';

/// What the app does when a repository fails.
///
/// Nothing tested this, and four of the five providers were written as though
/// it could not happen. On the mock build it cannot — `MockBusinessRepository`
/// and friends never throw. On the live build a dropped connection is routine.
///
/// The failure was not an error dialog missing. It was worse and quieter:
/// `_isLoading` was set true before the await and false after it, so a throw
/// skipped the reset. The spinner stayed up for the rest of the session, and
/// the exception escaped to the zone unhandled.

class _Offline implements Exception {
  @override
  String toString() => 'Offline';
}

class _ThrowingBusinesses implements BusinessRepository {
  @override
  Future<List<BusinessModel>> fetchAll() async => throw _Offline();
  @override
  Future<BusinessModel> registerBusiness({
    required String name,
    required BusinessCategory category,
    required String street,
    required String barangay,
    required String city,
    required String province,
  }) async => throw _Offline();
}

class _ThrowingNotifications implements NotificationsRepository {
  @override
  Future<List<NotificationEvent>> fetchAll() async => throw _Offline();
}

class _ThrowingAuth implements AuthRepository {
  @override
  Future<UserModel?> authenticate({
    required String email,
    required String password,
  }) async => throw _Offline();

  @override
  Future<bool> registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async => throw _Offline();

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<UserModel?> hydrateUser(String email) async => throw _Offline();

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
  }) async => throw UnimplementedError();
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  group('a failed load stops loading', () {
    test('businesses', () async {
      final provider = BusinessProvider(
        notifications: NotificationsProvider(
          repository: _ThrowingNotifications(),
        ),
        repository: _ThrowingBusinesses(),
      );
      await _settle();

      expect(provider.isLoading, isFalse, reason: 'the spinner must come down');
      expect(provider.hasLoadError, isTrue);
      expect(provider.businesses, isEmpty);
    });

    test('notifications', () async {
      final provider = NotificationsProvider(
        repository: _ThrowingNotifications(),
      );
      await _settle();

      expect(provider.isLoading, isFalse);
      expect(provider.hasLoadError, isTrue);
    });

    test('documents', () async {
      // DocumentsProvider builds its own repository, which reads
      // SharedPreferences. With no mock values registered the platform channel
      // is absent and the load throws — which is exactly the case under test.
      final provider = DocumentsProvider();
      await _settle();

      expect(
        provider.isLoading,
        isFalse,
        reason: 'a throwing load must still clear the loading flag',
      );
    });
  });

  group('signing in when the server cannot be reached', () {
    test('reports it, and does not blame the password', () async {
      final provider = AuthProvider(authRepository: _ThrowingAuth());

      final ok = await provider.login(
        email: 'juan@example.com',
        password: 'correct-horse',
        rememberMe: false,
      );

      expect(ok, isFalse);
      expect(
        provider.isLoading,
        isFalse,
        reason: 'the button must stop spinning',
      );
      expect(provider.errorMessage, isNotNull);
      expect(
        provider.errorMessage,
        isNot(contains('Incorrect')),
        reason:
            'a transport failure is not a wrong password — saying so sends '
            'the applicant to reset a password that was fine',
      );
    });

    test('registration reports it too', () async {
      final provider = AuthProvider(authRepository: _ThrowingAuth());

      final ok = await provider.register(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'juan@example.com',
        mobileNumber: '09171234567',
        password: 'correct-horse',
      );

      expect(ok, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNotNull);
    });
  });
}
