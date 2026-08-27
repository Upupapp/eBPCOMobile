import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_exception.dart';

/// The six failure classes an applicant can hit, and what each one tells them.
///
/// The taxonomy matters more than it looks: every one of these ends up as words
/// on a screen in front of someone whose building permit is at stake, and the
/// wrong words send them to the wrong place. A permissions problem shown as
/// "sign in again" is a loop; an outage shown as "check your details" blames
/// them for something that is not their fault.
void main() {
  group('RFC 9457 problem details', () {
    test('parses the shape the server sends', () {
      final problem = ProblemDetails.tryParse(
        '{"type":"/problems/precondition-unmet","title":"A precondition is unmet",'
        '"status":422,"detail":"No Order of Payment has been issued for this application, '
        'so there is nothing to pay.","correlationId":"01J9F8ZK3QYB7N2M4P6R8T0V2X"}',
      );

      expect(problem, isNotNull);
      expect(problem!.type, '/problems/precondition-unmet');
      expect(problem.detail, contains('nothing to pay'));
      expect(problem.correlationId, '01J9F8ZK3QYB7N2M4P6R8T0V2X');
    });

    test('collects field errors so a form can attach them to the right field', () {
      final problem = ProblemDetails.tryParse(
        '{"type":"/problems/validation-failed","title":"The request did not validate",'
        '"status":400,"errors":[{"pointer":"/mobileNumber","message":"must be 09XXXXXXXXX"},'
        '{"pointer":"/password","message":"too short"}]}',
      );

      expect(problem!.fieldErrors['/mobileNumber'], 'must be 09XXXXXXXXX');
      expect(problem.fieldErrors['/password'], 'too short');
    });

    test(
      'returns null rather than throwing on a body that is not problem+json',
      () {
        // A 503 from a load balancer is HTML. Turning that into a parse error
        // would report a contract bug where the truth is an outage.
        expect(ProblemDetails.tryParse('<html>502 Bad Gateway</html>'), isNull);
        expect(ProblemDetails.tryParse(''), isNull);
        expect(ProblemDetails.tryParse('{"unexpected":"shape"}'), isNull);
      },
    );
  });

  group('what the applicant is shown', () {
    test('prefers the server’s own detail, which knows the specifics', () {
      const exception = ApiException(
        ApiFailure.rejected,
        'engineering detail',
        statusCode: 422,
        problem: ProblemDetails(
          type: '/problems/precondition-unmet',
          title: 'A precondition is unmet',
          detail:
              'No Order of Payment has been issued for this application, so there is nothing to pay.',
        ),
      );

      expect(exception.applicantMessage, contains('nothing to pay'));
    });

    test('falls back to the taxonomy when the server sent no detail', () {
      const exception = ApiException(ApiFailure.timeout, 'engineering detail');

      expect(exception.applicantMessage, contains('did not respond in time'));
    });

    test(
      'never puts a status code or a stack trace in front of an applicant',
      () {
        // They cannot act on "HTTP 502", and being shown one suggests they did
        // something wrong.
        for (final failure in ApiFailure.values) {
          expect(
            failure.applicantMessage,
            isNot(matches(RegExp(r'\b[45]\d\d\b'))),
          );
          expect(failure.applicantMessage, isNot(contains('Exception')));
        }
      },
    );

    test('every failure class says something, and something different', () {
      final messages = ApiFailure.values.map((f) => f.applicantMessage).toSet();

      expect(messages, hasLength(ApiFailure.values.length));
      for (final message in messages) {
        expect(message.length, greaterThan(15));
      }
    });
  });

  group('what the app does next', () {
    test('offers retry only where retrying could plausibly work', () {
      expect(ApiFailure.network.isTransient, isTrue);
      expect(ApiFailure.timeout.isTransient, isTrue);
      expect(ApiFailure.server.isTransient, isTrue);

      // Retrying these produces the identical failure and wastes the
      // applicant's time and data.
      expect(ApiFailure.unauthorized.isTransient, isFalse);
      expect(ApiFailure.forbidden.isTransient, isFalse);
      expect(ApiFailure.notFound.isTransient, isFalse);
      expect(ApiFailure.rejected.isTransient, isFalse);
      expect(ApiFailure.malformed.isTransient, isFalse);
    });

    test(
      'exposes the problem type, so a screen can branch on a specific case',
      () {
        // "No Order of Payment" is a different screen from "not permitted", and
        // the status code alone only says 4xx.
        const exception = ApiException(
          ApiFailure.rejected,
          'x',
          problem: ProblemDetails(
            type: '/problems/order-of-payment-required',
            title: 'Not assessed',
          ),
        );

        expect(exception.problemType, '/problems/order-of-payment-required');
      },
    );

    test('reports no problem type when the server sent none', () {
      expect(
        const ApiException(ApiFailure.network, 'offline').problemType,
        isNull,
      );
    });
  });

  group('malformed is a contract bug, not an outage', () {
    test('is distinguished from a server failure', () {
      // The fix for one is a deploy; the fix for the other is waiting. Merging
      // them means an engineer waits for an outage that will never clear.
      expect(ApiFailure.malformed.isTransient, isFalse);
      expect(ApiFailure.server.isTransient, isTrue);
      expect(ApiFailure.malformed.applicantMessage, contains('report it'));
    });
  });
}
