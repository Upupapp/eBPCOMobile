import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Derives and checks a password verifier.
///
/// The app previously wrote the registered password to SharedPreferences in
/// plain text to simulate login. On a device holding real applicant data that
/// is indefensible under RA 10173 — SharedPreferences is not encrypted, and
/// anything with access to the app's data directory can read it.
///
/// What is stored now is a PBKDF2-HMAC-SHA256 verifier with a per-account
/// random salt. The password itself is never written anywhere, and the
/// verifier cannot be used to recover it.
///
/// This is the right local behaviour, not the right *product*. A production
/// build authenticates against a server and holds a session token in the
/// platform keychain or keystore. That needs a backend, which does not exist —
/// see M-01 in docs/MANUAL-TASKS.md.
class CredentialVerifier {
  const CredentialVerifier();

  /// Iteration count. Deliberately modest: this runs on the UI isolate of a
  /// mid-range Android phone at every login, and a count tuned for a server
  /// would make sign-in feel broken. Raise it once derivation moves off the
  /// main isolate.
  static const int defaultIterations = 12000;

  /// Lowered by the test harness. PBKDF2 is deliberately slow, which is the
  /// point in production and pure waste across a few hundred widget tests that
  /// are not exercising the derivation itself. Never set outside tests — see
  /// test/flutter_test_config.dart.
  @visibleForTesting
  static int iterationsOverride = 0;

  static int get iterations =>
      iterationsOverride > 0 ? iterationsOverride : defaultIterations;
  static const int _keyLengthBytes = 32;
  static const int _saltLengthBytes = 16;

  /// A fresh random salt, base64-encoded for storage.
  String newSalt([Random? random]) {
    final source = random ?? Random.secure();
    final bytes = Uint8List.fromList(
      List.generate(_saltLengthBytes, (_) => source.nextInt(256)),
    );
    return base64Encode(bytes);
  }

  /// The verifier for [password] under [salt], base64-encoded.
  String derive(String password, String salt) {
    final saltBytes = base64Decode(salt);
    final passwordBytes = utf8.encode(password);
    return base64Encode(_pbkdf2(passwordBytes, saltBytes));
  }

  /// Whether [password] matches [expectedVerifier] under [salt].
  ///
  /// Compares in constant time so a caller cannot learn how much of a guess
  /// was correct from how quickly the check fails.
  bool matches({
    required String password,
    required String salt,
    required String expectedVerifier,
  }) {
    final actual = derive(password, salt);
    return _constantTimeEquals(actual, expectedVerifier);
  }

  List<int> _pbkdf2(List<int> password, List<int> salt) {
    final hmac = Hmac(sha256, password);
    final output = <int>[];
    var block = 1;

    while (output.length < _keyLengthBytes) {
      // U1 = HMAC(password, salt || INT_32_BE(block))
      var u = hmac.convert([...salt, ..._int32BE(block)]).bytes;
      final accumulator = List<int>.from(u);

      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < accumulator.length; j++) {
          accumulator[j] ^= u[j];
        }
      }

      output.addAll(accumulator);
      block++;
    }

    return output.sublist(0, _keyLengthBytes);
  }

  List<int> _int32BE(int value) => [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ];

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}
