import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ebpco_user_app/core/api/api_client.dart';
import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/models/business_model.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/repositories/http_business_repository.dart';
import 'package:ebpco_user_app/core/repositories/http_notifications_repository.dart';

/// A client that answers with a canned body, so the repositories can be tested
/// against the contract's shapes without a server.
class _Canned extends http.BaseClient {
  _Canned(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );
  }
}

ApiClient clientFor(http.BaseClient canned) =>
    ApiClient(baseUrl: 'https://ebpco.example.gov.ph/api', httpClient: canned);

void main() {
  group('businesses', () {
    test('parses the contract shape', () async {
      final canned = _Canned(
        200,
        jsonEncode({
          'data': [
            {
              'id': '6b2f9c31-7a4d-4e88-b1c2-9d0e3f5a7b61',
              'name': 'Santos Hardware and Construction Supply',
              'category': 'Retail',
              'street': '142 Rizal Extension',
              'barangay': 'San Roque',
              'city': 'Quezon City',
              'province': 'Metro Manila',
              'registrationNumber': 'BN-2026-0041',
              'dateRegistered': '2026-01-15',
              'status': 'Active',
            },
          ],
        }),
      );

      final businesses = await HttpBusinessRepository(
        clientFor(canned),
      ).fetchAll();

      expect(businesses, hasLength(1));
      expect(businesses.first.name, 'Santos Hardware and Construction Supply');
      expect(businesses.first.category, BusinessCategory.retail);
      expect(businesses.first.status, BusinessStatus.active);
    });

    test('THROWS on a category the app does not know', () async {
      // Acceptance criterion: an unknown enum value produces a visible,
      // reportable failure — never a silently wrong one. Defaulting to "Other"
      // would file a business under the wrong category because the LGU added
      // one the app has not shipped yet.
      final canned = _Canned(
        200,
        jsonEncode({
          'data': [
            {
              'id': 'x',
              'name': 'n',
              'category': 'Agricultural',
              'street': 's',
              'barangay': 'b',
              'city': 'c',
              'province': 'p',
              'registrationNumber': 'r',
              'dateRegistered': '2026-01-15',
              'status': 'Active',
            },
          ],
        }),
      );

      await expectLater(
        HttpBusinessRepository(clientFor(canned)).fetchAll(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.failure, 'failure', ApiFailure.malformed)
              .having((e) => e.detail, 'detail', contains('Agricultural')),
        ),
      );
    });

    test(
      'throws on a missing required field rather than substituting a blank',
      () async {
        final canned = _Canned(
          200,
          jsonEncode({
            'data': [
              {'id': 'x'},
            ],
          }),
        );

        await expectLater(
          HttpBusinessRepository(clientFor(canned)).fetchAll(),
          throwsA(isA<ApiException>()),
        );
      },
    );
  });

  group('notifications', () {
    test('parses the wire name back to this app’s own type', () async {
      // The server adopted this app's catalog in TAB 08, so the wire name is
      // the kebab-case of the enum constant and parsing is a mechanical
      // reversal of that derivation.
      final canned = _Canned(
        200,
        jsonEncode({
          'data': [
            {
              'id': 'f8a0c2e4-7091-4d3b-85f7-8a0c2e4f6b8d',
              'type': 'order-of-payment-issued',
              'applicationId': '0f8d6a1e-2b4c-4d7e-9a10-3c5b7e9f1a2b',
              'createdAt': '2026-08-19T11:02:00+08:00',
              'readAt': null,
              'resolvedAt': null,
            },
          ],
        }),
      );

      final events = await HttpNotificationsRepository(
        clientFor(canned),
      ).fetchAll();

      expect(events.single.type, NotificationType.orderOfPaymentIssued);
      expect(events.single.readAt, isNull);
      expect(events.single.resolvedAt, isNull);
    });

    test('THROWS on a notification type the app cannot name', () async {
      // A notification the app cannot name has no icon, no category and no
      // destination. A blank card would be worse than failing.
      final canned = _Canned(
        200,
        jsonEncode({
          'data': [
            {
              'id': 'x',
              'type': 'something-invented-server-side',
              'createdAt': '2026-08-19T11:02:00+08:00',
            },
          ],
        }),
      );

      await expectLater(
        HttpNotificationsRepository(clientFor(canned)).fetchAll(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.detail,
            'detail',
            contains('drifted'),
          ),
        ),
      );
    });

    test('sorts newest first whatever order the server sent', () async {
      final canned = _Canned(
        200,
        jsonEncode({
          'data': [
            {
              'id': 'a',
              'type': 'approved',
              'createdAt': '2026-08-01T10:00:00+08:00',
            },
            {
              'id': 'b',
              'type': 'released',
              'createdAt': '2026-08-19T10:00:00+08:00',
            },
          ],
        }),
      );

      final events = await HttpNotificationsRepository(
        clientFor(canned),
      ).fetchAll();

      expect(events.map((e) => e.id), ['b', 'a']);
    });

    test('keeps read and resolved as separate facts', () async {
      // Reading never resolves. A feed that collapsed them would clear an
      // applicant's outstanding obligations by being glanced at.
      final canned = _Canned(
        200,
        jsonEncode({
          'data': [
            {
              'id': 'a',
              'type': 'revision-required',
              'createdAt': '2026-08-19T10:00:00+08:00',
              'readAt': '2026-08-19T11:00:00+08:00',
              'resolvedAt': null,
            },
          ],
        }),
      );

      final event = (await HttpNotificationsRepository(
        clientFor(canned),
      ).fetchAll()).single;

      expect(event.readAt, isNotNull);
      expect(event.resolvedAt, isNull);
    });
  });

  group('failures reach the caller typed', () {
    test(
      'a 403 arrives as forbidden with the server’s own explanation',
      () async {
        final canned = _Canned(
          403,
          jsonEncode({
            'type': '/problems/forbidden',
            'title': 'Not permitted',
            'status': 403,
            'detail':
                'This account does not hold the permission this action requires.',
          }),
        );

        await expectLater(
          HttpBusinessRepository(clientFor(canned)).fetchAll(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.failure, 'failure', ApiFailure.forbidden)
                .having(
                  (e) => e.applicantMessage,
                  'message',
                  contains('permission'),
                ),
          ),
        );
      },
    );

    test('a 5xx arrives as server, and is retryable', () async {
      final canned = _Canned(503, '<html>502 Bad Gateway</html>');

      await expectLater(
        HttpBusinessRepository(clientFor(canned)).fetchAll(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.failure, 'failure', ApiFailure.server)
              .having((e) => e.isTransient, 'isTransient', isTrue),
        ),
      );
    });
  });

  group('the notification payload reaches the body', () {
    // Found by diffing every model constructor against what each parser fills.
    // NotificationEvent declares ten fields and this parser set six, dropping
    // `payload` -- which is what `body` templates every specific message from.
    // Without it, "Your Order of Payment for E-BPCO-2026-000145 is ready:
    // PHP 5,000" degraded to "your application ... see the breakdown".

    Future<List<NotificationEvent>> fetch(Map<String, dynamic> row) async {
      final repo = HttpNotificationsRepository(
        clientFor(
          _Canned(
            200,
            jsonEncode({
              'data': [row],
            }),
          ),
        ),
      );
      return repo.fetchAll();
    }

    test('the reference and the template values both arrive', () async {
      final events = await fetch({
        'id': 'n-1',
        'type': 'order-of-payment-issued',
        'applicationId': 'app-1',
        'applicationNumber': 'E-BPCO-2026-000145',
        'createdAt': '2026-08-12T09:00:00+08:00',
        'payload': {'total': 'PHP 5,000.00'},
      });

      final event = events.single;
      expect(event.applicationNumber, 'E-BPCO-2026-000145');
      expect(event.payload['total'], 'PHP 5,000.00');
      // The whole point: the body is specific rather than generic.
      expect(event.body, contains('E-BPCO-2026-000145'));
      expect(event.body, contains('PHP 5,000.00'));
    });

    test('numbers in the payload are coerced, not rejected', () async {
      // The server sends counts and amounts as numbers; the body interpolates
      // everything into text anyway. A notification is not worth failing to
      // load over a value's JSON type.
      final events = await fetch({
        'id': 'n-2',
        'type': 'letter-of-instruction-issued',
        'applicationId': 'app-1',
        'createdAt': '2026-08-12T09:00:00+08:00',
        'payload': {'count': 3},
      });
      expect(events.single.payload['count'], '3');
      expect(events.single.body, contains('3 item'));
    });

    test('a missing or malformed payload is empty, not fatal', () async {
      for (final bad in [null, 'nope', 42, <String, dynamic>{}]) {
        final events = await fetch({
          'id': 'n-3',
          'type': 'approved',
          'applicationId': 'app-1',
          'createdAt': '2026-08-12T09:00:00+08:00',
          'payload': bad,
        });
        expect(events.single.payload, isEmpty, reason: '$bad');
        expect(events.single.body, isNotEmpty);
      }
    });

    test('null payload values are dropped rather than stringified', () async {
      // '${null}' is the string "null", which would render literally in a body.
      final events = await fetch({
        'id': 'n-4',
        'type': 'permit-generated',
        'applicationId': 'app-1',
        'createdAt': '2026-08-12T09:00:00+08:00',
        'payload': {'permitNumber': null},
      });
      expect(events.single.payload.containsKey('permitNumber'), isFalse);
      expect(events.single.body, isNot(contains('null')));
    });
  });
}
