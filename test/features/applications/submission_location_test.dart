import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/features/applications/presentation/widgets/submit_permit_application.dart';

/// The site, which the contract has always declared and the app never sent.
///
/// `POST /applications` types `location` as `[string, null]`. Every wizard
/// collects a lot number, a street, a barangay and a city; none of them were
/// joined and none were sent, so an office receiving a filing knew the permit
/// type and the applicant and not where the work is.

void main() {
  group('the line itself', () {
    test('reads the way an address is written', () {
      expect(
        constructionLocationLine(
          lot: '12',
          block: '4',
          street: 'Rizal Street',
          barangay: 'Poblacion',
          city: 'Castilla',
        ),
        'Lot 12, Block 4, Rizal Street, Poblacion, Castilla',
      );
    });

    test('empty parts are dropped, not rendered as commas', () {
      // "Lot 12, , , Castilla" is worse than "Lot 12, Castilla", and an
      // applicant who was never asked for a block number should not appear to
      // have skipped one.
      expect(
        constructionLocationLine(
          lot: '12',
          block: '  ',
          street: '',
          barangay: 'Poblacion',
          city: 'Castilla',
        ),
        'Lot 12, Poblacion, Castilla',
      );
    });

    test('nothing known is null, not an empty string', () {
      // The contract types the field as a string OR null, and '' is neither —
      // the same shape of error as the businessId that used to be sent empty.
      expect(constructionLocationLine(), isNull);
      expect(constructionLocationLine(lot: '  ', street: '', city: ''), isNull);
    });

    test('a lone city still says something useful', () {
      expect(constructionLocationLine(city: 'Castilla'), 'Castilla');
    });
  });

  test('every wizard with a site of its own sends one', () {
    // Sixteen of the nineteen. The two BFP clearances and the Certificate of
    // Occupancy have no site of their own — they attach to a building permit
    // that carries the address — so they pass nothing, and `location` is
    // omitted from the body rather than sent empty.
    final screens = Directory('lib/features/applications/presentation')
        .listSync()
        .whereType<Directory>()
        .expand((d) => d.listSync().whereType<File>())
        .where((f) => f.path.endsWith('_wizard_screen.dart'))
        .toList();
    expect(screens.length, greaterThanOrEqualTo(16));

    final without = [
      for (final screen in screens)
        if (screen.readAsStringSync().contains('submitPermitApplication(') &&
            !screen.readAsStringSync().contains(
              'location: constructionLocationLine(',
            ))
          screen.path.split('/').last,
    ];
    expect(
      without,
      // The three that genuinely have no address to send.
      hasLength(3),
      reason:
          'these file an application without saying where the work is: '
          '$without',
    );
  });

  test('the body omits the key rather than sending it empty', () {
    final repository = File(
      'lib/core/repositories/http_applications_repository.dart',
    ).readAsStringSync();
    expect(repository, contains("'location': ?location"));
  });
}
