import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
import 'package:ebpco_user_app/core/models/contact_verification.dart';
import 'package:ebpco_user_app/core/providers/contact_verification_provider.dart';
import 'package:ebpco_user_app/core/repositories/contact_verification_repository.dart';
import 'package:ebpco_user_app/features/profile/presentation/contact_verification_screen.dart';

/// What the screen says, and — as much — what it refuses to say.

final _now = DateTime(2026, 8, 28, 10);

class _Refusing implements ContactVerificationRepository {
  @override
  Future<ContactVerification> request(ContactVerification channel) async =>
      channel.copyWith(
        status: ContactVerificationStatus.pendingVerification,
        lastRequestedAt: _now,
      );

  @override
  Future<ContactVerification> confirm(
    ContactVerification channel, {
    required String code,
  }) async => throw const VerificationRejected(
    'That code has expired. Ask for a new one.',
  );
}

late ContactVerificationProvider provider;

Future<void> _open(
  WidgetTester tester, {
  ContactVerificationRepository? repository,
  String email = 'juan@example.com',
  String mobileNumber = '09171234567',
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  provider = ContactVerificationProvider(
    repository:
        repository ?? MockContactVerificationRepository(clock: () => _now),
    email: email,
    mobileNumber: mobileNumber,
    clock: () => _now,
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<ContactVerificationProvider>.value(
      value: provider,
      child: const MaterialApp(home: ContactVerificationScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('both channels are listed with their own status', (tester) async {
    await _open(tester);

    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('juan@example.com'), findsOneWidget);
    expect(find.text('09171234567'), findsOneWidget);
    expect(find.text('Unverified'), findsNWidgets(2));
  });

  testWidgets('nothing is gated on verification, and it says so', (
    tester,
  ) async {
    // Whether an unverified applicant may file is the LGU's decision. Not
    // taking it is one thing; leaving the applicant to assume the worst is
    // another.
    await _open(tester);
    expect(
      find.textContaining(
        'You can file, pay and claim a permit whether or '
        'not these are verified',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the two office-side methods are named, not hidden', (
    tester,
  ) async {
    // An applicant who cannot receive a code — a shared number, a lost mailbox
    // — needs to know there is another route and that it is at the counter.
    await _open(tester);
    expect(
      find.textContaining(
        'confirm your details in person, or match them '
        'against an identity document',
      ),
      findsOneWidget,
    );
  });

  testWidgets('asking moves the channel to Pending and offers the code box', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.text('Send verification link'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Pending Verification'), findsOneWidget);
    expect(find.text('Code from the email'), findsOneWidget);
    expect(find.text('Send it again'), findsOneWidget);
  });

  testWidgets('a rejected code shows the office\'s reason on the channel', (
    tester,
  ) async {
    await _open(tester, repository: _Refusing());

    await tester.tap(find.text('Send code by SMS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField).first, '000000');
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Verification Failed'), findsOneWidget);
    expect(
      find.textContaining('That code has expired'),
      findsWidgets,
      reason: '"Failed" alone leaves the applicant to guess',
    );
  });

  testWidgets('confirming against the real mock says it cannot be done yet', (
    tester,
  ) async {
    // And crucially does not show a tick.
    await _open(tester);

    await tester.tap(find.text('Send verification link'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('has not switched on'), findsOneWidget);
    expect(find.text('Verified'), findsNothing);
    expect(provider.of(ContactChannel.email).isVerified, isFalse);
  });

  testWidgets('a channel with nothing in it offers no button', (tester) async {
    await _open(tester, mobileNumber: '');

    expect(find.text('Not provided'), findsOneWidget);
    expect(find.text('Send code by SMS'), findsNothing);
    expect(find.textContaining('Add one from Edit Profile'), findsOneWidget);
  });
}
