import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/api/application_dto.dart';
import 'package:ebpco_user_app/core/models/application_detail.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/models/permit_classification.dart';

/// A full §7.2 ApplicationDetail payload.
Map<String, dynamic> _payload({
  String lifecycleStatus = 'Under Evaluation',
  Object? classification = 'Highly Technical',
  Object? payment,
  Object? instructions,
  Object? timeline,
  Object? permit,
}) => {
  'id': 'app-1',
  'referenceNumber': 'E-BPCO-2026-000145',
  'businessId': 'biz-1',
  'businessName': "Juan's General Merchandise",
  'permitType': 'New Construction',
  'applicationAction': 'New',
  'lifecycleStatus': lifecycleStatus,
  'classification': classification,
  'dateSubmitted': '2026-08-03T09:15:00+08:00',
  'payment': ?payment,
  'instructions': ?instructions,
  'timeline': ?timeline,
  'permit': ?permit,
};

void main() {
  group('core fields', () {
    test('parses the wire contract into the domain model', () {
      final application = ApplicationDto.parse(_payload());

      expect(application.id, 'app-1');
      expect(application.applicationNumber, 'E-BPCO-2026-000145');
      expect(application.permitTypeLabel, 'New Construction');
      expect(
        application.lifecycleStatus,
        ApplicationLifecycleStatus.underEvaluation,
      );
      expect(application.classification, PermitClassification.highlyTechnical);
      expect(application.type, ApplicationType.newPermit);
    });

    test('derives the applicant status from the lifecycle, never separately', () {
      // Two fields that could disagree are two fields that eventually will.
      final application = ApplicationDto.parse(
        _payload(lifecycleStatus: 'Revision Required'),
      );

      expect(application.status, ApplicationStatus.underReview);
      expect(application.applicantStatus, ApplicationStatus.underReview);
      expect(application.requiresApplicantAction, isTrue);
    });

    test('every one of the 19 admin labels round-trips', () {
      const labels = [
        'Draft', 'Submitted', 'Received', 'Document Verification',
        'Under Evaluation', 'Revision Required', 'Assessed',
        'Payment Submitted', 'Payment Under Verification', 'Payment Verified',
        'For Approval', 'Approved', 'Permit Generated', 'Ready for Release',
        'Released', 'Completed', 'Rejected', 'Cancelled', 'Expired',
      ];
      expect(labels, hasLength(ApplicationLifecycleStatus.values.length));

      for (final label in labels) {
        final parsed = ApplicationDto.parse(_payload(lifecycleStatus: label));
        expect(parsed.lifecycleStatus!.adminLabel, label);
      }
    });

    test('a classification the LGU has not set stays null', () {
      final application = ApplicationDto.parse(
        _payload(classification: null),
      );
      // Which is what makes Home render "Awaiting classification" instead of
      // inventing a countdown.
      expect(application.classification, isNull);
    });

    test('dates arrive as local time', () {
      final application = ApplicationDto.parse(_payload());
      expect(application.submittedDate.isUtc, isFalse);
    });
  });

  group('refusing to guess', () {
    test('an unknown lifecycle status throws rather than defaulting', () {
      // Silently rendering an unrecognised status as "Submitted" would tell an
      // applicant their permit is progressing when it may have been rejected.
      expect(
        () => ApplicationDto.parse(
          _payload(lifecycleStatus: 'Under Adjudication'),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            ApiFailure.malformed,
          ),
        ),
      );
    });

    test('an unknown classification throws', () {
      expect(
        () => ApplicationDto.parse(_payload(classification: 'Moderate')),
        throwsA(isA<ApiException>()),
      );
    });

    test('a missing reference number throws', () {
      final json = _payload()..remove('referenceNumber');
      expect(() => ApplicationDto.parse(json), throwsA(isA<ApiException>()));
    });

    test('a fee sent as a float throws instead of being rounded', () {
      expect(
        () => ApplicationDto.parse(
          _payload(
            payment: {
              'status': 'Not Yet Available',
              'orderOfPayment': {
                'number': 'OP-1',
                'assessedAt': '2026-08-10T00:00:00+08:00',
                'fees': {'filing': 500.5},
              },
            },
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.detail,
            'detail',
            contains('whole centavos'),
          ),
        ),
      );
    });

    test('an Order of Payment without its breakdown throws', () {
      expect(
        () => ApplicationDto.parse(
          _payload(
            payment: {
              'status': 'Not Yet Available',
              'orderOfPayment': {
                'number': 'OP-1',
                'assessedAt': '2026-08-10T00:00:00+08:00',
              },
            },
          ),
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('nested records', () {
    test('an Order of Payment totals its centavos exactly', () {
      final application = ApplicationDto.parse(
        _payload(
          payment: {
            'status': 'Not Yet Available',
            'orderOfPayment': {
              'number': 'OP-2026-004821',
              'assessedAt': '2026-08-10T00:00:00+08:00',
              'assessedBy': 'Assessment Section, OBO',
              'dueDate': '2026-09-09T00:00:00+08:00',
              'fees': {
                'filing': 50000,
                'processing': 120000,
                'architectural': 285050,
                'structural': 341275,
                'electrical': 96500,
                'others': 42000,
              },
            },
          },
        ),
      );

      final order = application.payment!.orderOfPayment!;
      expect(order.number, 'OP-2026-004821');
      expect(order.total.centavos, 934825);
      expect(order.total.formatted, 'PHP 9,348.25');
      expect(order.isConsistent, isTrue);
      expect(
        application.payment!.status,
        PaymentAssessmentStatus.notYetAvailable,
      );
    });

    test('open instruction items are counted when the server omits the total', () {
      final application = ApplicationDto.parse(
        _payload(
          instructions: [
            {
              'id': 'loi-1',
              'issuedAt': '2026-08-05T00:00:00+08:00',
              'issuedBy': 'Legal Evaluator',
              'items': [
                {
                  'id': 'i1',
                  'subject': 'Transfer Certificate of Title',
                  'remark': 'Submit a Certified True Copy.',
                },
                {
                  'id': 'i2',
                  'subject': 'Structural plan',
                  'remark': 'Must carry the dry seal.',
                  'resolvedAt': '2026-08-06T00:00:00+08:00',
                },
              ],
            },
          ],
        ),
      );

      expect(application.openInstructionCount, 1);
      expect(application.openInstruction!.items, hasLength(2));
      expect(application.openInstruction!.resolvedCount, 1);
      expect(application.requiresApplicantAction, isTrue);
      // Verbatim, as the evaluator wrote it.
      expect(
        application.openInstruction!.items.first.remark,
        'Submit a Certified True Copy.',
      );
    });

    test('the timeline is sorted oldest-first whatever order it arrives in', () {
      final application = ApplicationDto.parse(
        _payload(
          timeline: [
            {
              'status': 'Under Evaluation',
              'occurredAt': '2026-08-06T00:00:00+08:00',
            },
            {
              'status': 'Submitted',
              'occurredAt': '2026-08-03T00:00:00+08:00',
            },
            {
              'status': 'Received',
              'occurredAt': '2026-08-04T00:00:00+08:00',
            },
          ],
        ),
      );

      // The revision-loop rendering depends on chronology, so order is not
      // left to the server's discretion.
      expect(
        application.timeline.map((e) => e.status).toList(),
        [
          ApplicationLifecycleStatus.submitted,
          ApplicationLifecycleStatus.received,
          ApplicationLifecycleStatus.underEvaluation,
        ],
      );
    });

    test('evaluations sort into stage order', () {
      final application = ApplicationDto.parse(
        _payload()
          ..['evaluations'] = [
            {'stage': 'OBO', 'result': 'Pending'},
            {'stage': 'Initial', 'result': 'Passed'},
            {'stage': 'Fire Safety', 'result': 'Pending'},
          ],
      );

      expect(
        application.evaluations.map((e) => e.stage).toList(),
        [
          EvaluationStage.initial,
          EvaluationStage.fireSafety,
          EvaluationStage.obo,
        ],
      );
    });

    test('a permit carries its PD 1096 commencement deadline', () {
      final application = ApplicationDto.parse(
        _payload(
          lifecycleStatus: 'Released',
          permit: {
            'permitNumber': 'BP-2026-0001',
            'issuedDate': '2026-05-04T00:00:00+08:00',
            'scope': 'Two-storey residential',
            'conditions': ['Notify the OBO before commencing'],
          },
        ),
      );

      expect(application.permit!.permitNumber, 'BP-2026-0001');
      expect(application.commenceByDate, DateTime(2027, 5, 4));
      expect(application.permit!.conditions, hasLength(1));
      // Never from the wire — it is a path on this device.
      expect(application.permit!.isAvailableOffline, isFalse);
    });

    test('absent optional sections parse as empty, not as failures', () {
      final application = ApplicationDto.parse(_payload());

      expect(application.timeline, isEmpty);
      expect(application.evaluations, isEmpty);
      expect(application.instructions, isEmpty);
      expect(application.inspection, isNull);
      expect(application.permit, isNull);
      expect(application.payment, isNull);
    });
  });

  test('parseList rejects a non-object row rather than skipping it', () {
    expect(
      () => ApplicationDto.parseList([_payload(), 'oops']),
      throwsA(isA<ApiException>()),
    );
  });
}
