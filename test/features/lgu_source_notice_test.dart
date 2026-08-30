import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/contract/lgu_source_notice.dart';
import 'package:ebpco_user_app/core/contract/requirements_catalog.dart';

/// The app may not present a national compilation as the LGU's own word.
///
/// The requirements catalogue records, per permit type, whether an entry came
/// from an actual Castilla or BFP form. **Fifteen of nineteen did not**, and
/// `RequirementSource`'s own doc comment says to carry that to the applicant:
/// *"A requirement the LGU has not confirmed must not be shown in the same
/// voice as PD 1096."*
///
/// The pre-flight screen carried it. The **Citizen's Charter** screen did not
/// — the surface titled with the name of a statutory document, listing which
/// offices are involved and **where to secure each item**. An applicant makes
/// trips on that column.
///
/// Same defect class as the fabricated support address, and worse: that one
/// cost an email, this one costs a journey.

String _code(String path) => File(path)
    .readAsStringSync()
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .split('\n')
    .map((line) {
      final comment = line.indexOf('//');
      return comment >= 0 && line.substring(0, comment).trim().isEmpty
          ? ''
          : line;
    })
    .join('\n');

const _charterScreen =
    'lib/features/profile/presentation/citizens_charter_screen.dart';
const _preFlight =
    'lib/features/applications/presentation/pre_flight_screen.dart';

void main() {
  test('the measurement this rests on', () {
    // If these figures move, the LGU has supplied something and the notices
    // below need re-reading rather than re-asserting.
    final catalog = File(
      'lib/core/contract/requirements_catalog.dart',
    ).readAsStringSync();
    expect(
      RegExp('verified: false').allMatches(catalog).length,
      15,
      reason:
          'fifteen of the nineteen permits are not built from a Castilla '
          'form. If this fell, say which permit was confirmed and how',
    );
    expect(RegExp('verified: true').allMatches(catalog).length, 4);
  });

  test('confirmation is read from the catalogue, not held twice', () {
    // Two answers to one question is how they drift apart.
    for (final label in const [
      'Building Permit – New Construction',
      'Fencing Permit',
    ]) {
      expect(
        LguSourceNotice.isConfirmedForPermit(label),
        requirementsForLabel(label)?.verified ?? false,
        reason: label,
      );
    }
    expect(
      LguSourceNotice.isConfirmedForPermit('Not A Permit'),
      isFalse,
      reason:
          'an unknown permit must read as unconfirmed, not as confirmed by '
          'the absence of an entry',
    );
  });

  test('the Citizen\'s Charter screen says where its content comes from', () {
    // Always, not conditionally: even the four permits built from a genuine
    // Castilla form have no CHARTER entry sourced from Castilla's published
    // charter. The offices, the where-to-secure column and the fee basis are a
    // national compilation for all nineteen.
    expect(
      _code(_charterScreen),
      contains('LguSourceNotice.charterProvenance'),
    );
    expect(
      LguSourceNotice.charterProvenance,
      contains('has not been supplied to this app'),
    );
    expect(
      LguSourceNotice.charterProvenance,
      contains('confirm them with the office'),
      reason: '"may be inaccurate" tells an applicant nothing they can act on',
    );
  });

  test('and it carries the per-permit caveat too', () {
    expect(
      _code(_charterScreen),
      contains('LguSourceNotice.isConfirmedForPermit'),
    );
    expect(
      _code(_charterScreen),
      contains('LguSourceNotice.unconfirmedRequirements'),
    );
  });

  test('both surfaces use the one notice, in the same words', () {
    // The pre-flight screen wrote the caveat out inline. Two screens with two
    // copies of one sentence is how one gets corrected and the other does not
    // — which has happened twice in this repository already.
    for (final path in const [_charterScreen, _preFlight]) {
      final code = _code(path);
      expect(
        code,
        contains('LguSourceNotice.unconfirmedRequirements'),
        reason: path,
      );
      expect(
        code,
        isNot(contains('follow national practice and are still')),
        reason: '$path holds its own copy of the sentence',
      );
    }
  });

  test('the statutory pledge is still stated as statutory', () {
    // The one part of the charter that IS national law. Blanketing the whole
    // screen in doubt would understate RA 11032, which the applicant can hold
    // the office to.
    expect(
      _code(_charterScreen),
      contains('LguSourceNotice.pledgeIsStatutory'),
    );
    expect(LguSourceNotice.pledgeIsStatutory, contains('RA 11032'));
  });
}
