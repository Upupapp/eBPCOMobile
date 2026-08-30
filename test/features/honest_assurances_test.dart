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
  group('drafts promise exactly what they now do', () {
    // Inverted 30 August 2026. Until M-48 the only honest thing either
    // surface could say was that a draft dies with the process, and this
    // group held them to it. All nineteen wizards now persist, so the promise
    // is allowed back — but only WITH the caveat that makes it true, because
    // the half of it that is still false is the half an applicant would
    // discover at the worst moment.
    const surfaces = [
      'lib/features/applications/presentation/widgets/'
          'before_you_start_card.dart',
      'lib/features/applications/presentation/application_list_screen.dart',
    ];

    /// The copy as an applicant reads it, not as the file stores it.
    ///
    /// dart format breaks a long sentence across adjacent string literals, so
    /// a raw `contains` on the source misses any phrase that happens to span
    /// the wrap — which is precisely how a test like this passes while the
    /// sentence it guards says something else. Joined first.
    String copy(String file) =>
        _read(file).replaceAll(RegExp(r"'\s*\n\s*'"), '');

    test('the joined copy is not empty', () {
      for (final file in surfaces) {
        expect(copy(file).length, greaterThan(200), reason: file);
      }
    });

    test('both say the draft survives closing the app', () {
      expect(
        copy(surfaces.first),
        contains(
          'You can save your progress as a draft and come back to it later, '
          'even after closing the app.',
        ),
      );
      expect(
        copy(surfaces.last),
        contains(
          'Applications you start but do not finish are saved here, and are '
          'still here after you close the app,',
        ),
      );
    });

    test('both say the attachments are kept, AND that some may not be', () {
      // Inverted a second time on 30 August, once attachments were copied
      // into the app's own storage and stored by name rather than by path.
      // The second half is what keeps it honest: a file the applicant cleared
      // between saving and resuming is gone, and a promise with no room for
      // that would send them back to a step they believe is finished.
      expect(
        copy(surfaces.first),
        contains(
          'Your attached files are kept too — if any are missing when you '
          'return, the draft will say which.',
        ),
      );
      expect(
        copy(surfaces.last),
        contains(
          'with the files you attached. Anything missing is named on the '
          'draft itself.',
        ),
      );
    });

    test('the stale caveat is gone from both', () {
      // True of every wizard until M-48, and now true of none.
      for (final file in surfaces) {
        expect(copy(file), isNot(contains('only while the app stays open')));
        expect(
          copy(file),
          isNot(contains('Closing it loses an unsubmitted application')),
        );
        expect(
          copy(file),
          isNot(contains('Attached files are not kept')),
          reason: 'true for one day, and now true of nothing',
        );
      }
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
