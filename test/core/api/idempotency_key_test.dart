import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/idempotency_key.dart';

/// The header the app sent on nothing until M-47.
///
/// The contract makes `Idempotency-Key` required on every POST an applicant
/// can make, with `format: uuid`. A server validating that format rejects
/// anything else, and "it looked like a uuid" is not the same as being one.
void main() {
  final pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('the shape is RFC 4122 version 4', () {
    for (var i = 0; i < 200; i++) {
      final key = newIdempotencyKey();
      expect(key, matches(pattern), reason: key);
    }
  });

  test('the version and variant bits are set, not merely random', () {
    // Both are forced. A generator that produced 36 random hex characters
    // would pass a length check and fail a server's format validation roughly
    // fifteen times in sixteen — and it would fail it in production, on a
    // filing, rather than here.
    //
    // Seeded so this asserts the masking rather than luck: every byte is
    // 0x00 before masking, and the two that carry the bits come back set.
    final zeros = newIdempotencyKey(_FixedRandom(0));
    expect(zeros, '00000000-0000-4000-8000-000000000000');

    final ones = newIdempotencyKey(_FixedRandom(255));
    expect(ones, 'ffffffff-ffff-4fff-bfff-ffffffffffff');
  });

  test('two keys are not the same key', () {
    // The whole point is that one operation has one key and two operations do
    // not share one. A constant would make every filing a replay of the first.
    final keys = {for (var i = 0; i < 1000; i++) newIdempotencyKey()};
    expect(keys, hasLength(1000));
  });
}

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;

  @override
  int nextInt(int max) => value % max;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}
