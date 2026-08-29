import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Assurances the app makes to an applicant, against what it actually does.
///
/// Two false ones were found by sweeping for assurance-shaped copy and checking
/// each against the code:
///
/// * **Drafts.** Two places promised an unfinished application would be waiting
///   later. Nothing is written to disk; every draft dies with the process. The
///   Before-you-start card was narrowed first and its sibling on the Drafts
///   empty state was missed — fixing one copy and leaving the other is a
///   recurring defect here, so both are now asserted together.
/// * **Offline permits.** `downloadPermit` writes no file — it sets a path and
///   its own comment says it "stands in for writing the fetched PDF". The
///   screen said *"Saved to this device. Available without a connection."* That
///   is the costliest kind of false assurance, because an applicant would rely
///   on it at the counter, offline, with nothing to show.
///
/// These tests are deliberately about **copy**, which is unusual and is the
/// point: a promise is a feature. The assertions fail when the promise returns,
/// which is the moment to check whether the capability arrived with it.

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('drafts do not promise to survive', () {
    const claims = [
      'You can save your progress as a draft.',
      'are saved here so you',
    ];

    test('neither the card nor the Drafts empty state claims persistence', () {
      final card = _read(
        'lib/features/applications/presentation/widgets/'
        'before_you_start_card.dart',
      );
      final list = _read(
        'lib/features/applications/presentation/application_list_screen.dart',
      );

      for (final claim in claims) {
        expect(
          card.contains("'$claim'"),
          isFalse,
          reason: 'the Before-you-start card promises "$claim" again',
        );
        expect(
          list.contains(claim),
          isFalse,
          reason: 'the Drafts empty state promises "$claim" again',
        );
      }
    });

    test('both say what is actually true instead', () {
      // Asserted positively as well, so deleting the honest sentence does not
      // quietly pass by leaving neither claim nor caveat.
      expect(
        _read(
          'lib/features/applications/presentation/widgets/'
          'before_you_start_card.dart',
        ),
        contains('only while the app stays open'),
      );
      expect(
        _read(
          'lib/features/applications/presentation/application_list_screen.dart',
        ),
        contains('Closing it loses an unsubmitted application'),
      );
    });
  });

  group('the permit does not promise to work offline', () {
    test('nothing claims the file is saved to the device', () {
      final screen = _read(
        'lib/features/applications/presentation/detail/'
        'digital_permit_screen.dart',
      );

      for (final claim in const [
        'Saved to this device. Available without a ',
        'Permit saved to this device.',
        'show without a ',
      ]) {
        expect(
          screen.contains(claim),
          isFalse,
          reason:
              'the permit screen claims "$claim" again. If downloadPermit now '
              'writes a real file, restore the copy AND delete this '
              'expectation — see M-49.',
        );
      }
    });

    test('and downloadPermit still writes no file, which is why', () {
      // The assertion that keeps the one above honest. If this fails, the
      // capability has arrived and the copy should be restored rather than
      // the caveat kept.
      final provider = _read('lib/core/providers/applications_provider.dart');
      final start = provider.indexOf('Future<void> downloadPermit(');
      expect(start, greaterThan(0));
      final body = provider.substring(start, provider.indexOf('\n  }', start));

      for (final write in const [
        'File(',
        'writeAsBytes',
        'ObjectStore',
        'store.put',
      ]) {
        expect(
          body.contains(write),
          isFalse,
          reason:
              'downloadPermit now writes something ($write) — good; '
              'restore the offline copy on the permit screen',
        );
      }
    });
  });

  test('the password reset already tells the truth, and must keep doing so', () {
    // Found honest during the same sweep, and worth locking: it says outright
    // that no real email is sent. That is the pattern the two fixes above
    // follow.
    expect(
      _read(
        'lib/features/authentication/presentation/forgot_password_screen.dart',
      ),
      contains('no real email is sent'),
    );
  });
}
