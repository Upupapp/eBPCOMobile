import 'dart:async';

import 'package:ebpco_user_app/core/services/credential_verifier.dart';

/// Runs once before the whole suite.
///
/// PBKDF2 is deliberately expensive, which is correct in production and pure
/// waste in a few hundred widget tests that only need login to succeed or
/// fail. Lowering the iteration count here keeps the suite fast without
/// weakening the shipped default, and the derivation itself is still exercised
/// at full strength by credential_verifier_test.dart.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  CredentialVerifier.iterationsOverride = 10;
  await testMain();
}
