import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/certificate_pinner.dart';

/// A certificate whose DER bytes we choose, so pin arithmetic is testable
/// without a live handshake.
class _FakeCertificate implements X509Certificate {
  _FakeCertificate(this.der);

  @override
  final Uint8List der;

  @override
  DateTime get endValidity => DateTime(2027);
  @override
  DateTime get startValidity => DateTime(2026);
  @override
  String get issuer => 'CN=Test Issuer';
  @override
  String get subject => 'CN=ebpco.example.gov.ph';
  @override
  Uint8List get sha1 => Uint8List(20);
  @override
  String get pem =>
      '-----BEGIN CERTIFICATE-----\n${base64.encode(der)}\n-----END CERTIFICATE-----';
}

X509Certificate certificateFrom(String seed) =>
    _FakeCertificate(Uint8List.fromList(utf8.encode(seed)));

String pinFor(String seed) =>
    base64.encode(sha256.convert(utf8.encode(seed)).bytes);

void main() {
  final current = certificateFrom('the-lgu-certificate-in-force');
  final next = certificateFrom('the-certificate-that-replaces-it');
  final attacker = certificateFrom('a-certificate-from-an-installed-root');

  group('a pinned connection', () {
    final pinner = CertificatePinner(
      pins: {
        pinFor('the-lgu-certificate-in-force'),
        pinFor('the-certificate-that-replaces-it'),
      },
    );

    test('accepts the certificate in force', () {
      expect(pinner.accepts(current), isTrue);
      expect(verifyConnection(pinner, current), PinVerdict.accepted);
    });

    test('accepts the backup pin, so a renewal needs no app update', () {
      // An app pinned to one fingerprint stops working for every installed user
      // the moment the certificate is renewed. The backup is the next
      // certificate's pin, published before the rotation.
      expect(verifyConnection(pinner, next), PinVerdict.accepted);
    });

    test('REFUSES a certificate signed by an attacker-installed root', () {
      // The platform trust store does not help here: the attacker's root is in
      // it. That is the whole reason for pinning.
      expect(pinner.accepts(attacker), isFalse);
      expect(verifyConnection(pinner, attacker), PinVerdict.rejected);
    });

    test('refuses a connection presenting no certificate at all', () {
      expect(verifyConnection(pinner, null), PinVerdict.rejected);
    });

    test('computes the fingerprint over the DER encoding', () {
      expect(
        CertificatePinner.fingerprintOf(current),
        pinFor('the-lgu-certificate-in-force'),
      );
    });
  });

  group('the kill switch', () {
    test('degrades to platform trust rather than to no TLS', () {
      // If both pins are wrong — an unstaged rotation, a mis-issued certificate
      // — every install is bricked until the stores approve an update, which
      // takes days. This is the lever that buys those days.
      const disabled = CertificatePinner(pins: {}, enabled: false);

      expect(disabled.accepts(attacker), isTrue);
      expect(verifyConnection(disabled, attacker), PinVerdict.pinningDisabled);
    });

    test('is a build-time flag, not something a network can set', () {
      // A remotely disableable pin can be disabled by whoever is doing the
      // intercepting. The constructor is const, so the value is fixed at build.
      const pinner = CertificatePinner(pins: {'x'}, enabled: false);
      expect(pinner.enabled, isFalse);
    });
  });

  group('misconfiguration', () {
    test(
      'refuses to run enabled with no pins, rather than bricking silently',
      () {
        // Enabled with an empty set would accept nothing. Failing loudly at the
        // first request beats every applicant seeing a connection error.
        const misconfigured = CertificatePinner(pins: {});

        expect(() => misconfigured.accepts(current), throwsStateError);
      },
    );
  });

  group('the HTTP client it builds', () {
    test('does not accept a certificate the platform already rejected', () {
      // badCertificateCallback fires only after the OS has refused. Returning
      // true there would be overriding the platform's own verdict.
      // `badCertificateCallback` is a setter with no getter, so the callback is
      // a named method and asserted directly.
      final pinner = CertificatePinner(pins: {pinFor('x')});

      expect(
        pinner.rejectBadCertificate(current, 'ebpco.example.gov.ph', 443),
        isFalse,
      );
      expect(
        pinner.rejectBadCertificate(attacker, 'ebpco.example.gov.ph', 443),
        isFalse,
      );

      pinner.buildClient().close();
    });
  });
}
