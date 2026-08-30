import 'dart:math';

/// A key that makes a retry of one operation the same operation.
///
/// **The contract makes `Idempotency-Key` a REQUIRED header on every POST an
/// applicant can make** — register, file, cancel, answer an instruction,
/// register a business, save a professional, upload a document, report a
/// payment, register a device — and this app sent it on none of them. Measured
/// 30 August 2026: `grep -rn Idempotency lib` returned nothing.
///
/// That is a third class of divergence, invisible to the write-body gate
/// because it compares bodies and this is a header. It is also the one with
/// the worst failure mode if the server ever stopped requiring it: without a
/// key, a retry after a timeout is a SECOND filing, and an applicant who taps
/// again on a slow connection ends up with two permit applications and two
/// fees.
///
/// RFC 4122 version 4, from `Random.secure()`. Written here rather than taking
/// a dependency: it is sixteen bytes and two bit-masks, and the contract asks
/// for `format: uuid`, not for any particular package.
String newIdempotencyKey([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  // Version 4 in the high nibble of byte 6, and the RFC 4122 variant in the
  // top two bits of byte 8. A server validating the format rejects anything
  // else, and "it looked like a uuid" is not the same as being one.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int start, int end) => bytes
      .sublist(start, end)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
