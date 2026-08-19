import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Refuses a TLS connection to anything but the LGU's own certificate.
///
/// Without pinning, a device with an attacker-installed root — a managed work
/// phone, a compromised public network with a captive portal, a malicious
/// profile — can terminate TLS transparently and read every applicant's session
/// token and identity documents. The platform trust store alone does not
/// prevent that, because the attacker's root is *in* the trust store.
///
/// Two things make this survivable in operation rather than a foot-gun:
///
/// **A backup pin.** Certificates are renewed, and an app pinned to one
/// fingerprint stops working for every installed user the moment it is. The
/// backup is the next certificate's pin, published before the rotation, so the
/// switch needs no app update.
///
/// **A kill switch.** If both pins are wrong — a rotation nobody staged, a
/// mis-issued certificate — every install is bricked until the stores approve
/// an update, which takes days. `enabled: false` is the lever that buys those
/// days, and it is a build-time flag rather than a remote one on purpose: a
/// remotely disableable pin can be disabled by whoever is doing the
/// intercepting.
class CertificatePinner {
  const CertificatePinner({
    required this.pins,
    this.enabled = true,
  });

  /// Base64 SHA-256 of the certificate's DER encoding. At least two in any
  /// real deployment: the current one and the next.
  final Set<String> pins;

  final bool enabled;

  /// Whether this certificate is one we pinned.
  ///
  /// Returns true when disabled, so the kill switch degrades to platform trust
  /// rather than to no TLS at all.
  bool accepts(X509Certificate certificate) {
    if (!enabled) return true;
    if (pins.isEmpty) {
      // An empty pin set with pinning enabled would accept nothing and brick
      // the app. Refusing to be configured that way is safer than either
      // failing open or failing closed silently.
      throw StateError('certificate pinning is enabled but no pins are configured');
    }
    return pins.contains(fingerprintOf(certificate));
  }

  static String fingerprintOf(X509Certificate certificate) =>
      base64.encode(sha256.convert(certificate.der).bytes);

  /// The `badCertificateCallback` this pinner installs.
  ///
  /// Always false. It fires only when the platform has ALREADY rejected the
  /// certificate, so returning true would be overriding the OS's own verdict —
  /// which is the single most common way pinning gets accidentally disabled,
  /// because it is also the easiest way to make a self-signed staging server
  /// work. Pinning is applied to the verified chain by [accepts]; this stays
  /// shut.
  ///
  /// Named and public so it can be asserted on: `badCertificateCallback` is a
  /// setter with no getter, so a test cannot read it back off the client.
  bool rejectBadCertificate(X509Certificate certificate, String host, int port) => false;

  /// Builds an [HttpClient] that will not complete a handshake with a
  /// certificate the platform rejects.
  HttpClient buildClient() {
    final client = HttpClient();
    client.badCertificateCallback = rejectBadCertificate;
    return client;
  }
}

/// The outcome of checking a live connection, kept separate from the pinner so
/// the decision is testable without a socket.
enum PinVerdict { accepted, rejected, pinningDisabled }

PinVerdict verifyConnection(CertificatePinner pinner, X509Certificate? certificate) {
  if (!pinner.enabled) return PinVerdict.pinningDisabled;
  if (certificate == null) return PinVerdict.rejected;
  return pinner.accepts(certificate) ? PinVerdict.accepted : PinVerdict.rejected;
}
