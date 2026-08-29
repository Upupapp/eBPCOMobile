import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/api/api_exception.dart';
import 'package:ebpco_user_app/core/api/application_dto.dart';
import 'package:ebpco_user_app/core/models/application_detail.dart';
import 'package:ebpco_user_app/core/contract/admin_vocabulary.dart';
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

    test(
      'derives the applicant status from the lifecycle, never separately',
      () {
        // Two fields that could disagree are two fields that eventually will.
        final application = ApplicationDto.parse(
          _payload(lifecycleStatus: 'Revision Required'),
        );

        expect(application.status, ApplicationStatus.underReview);
        expect(application.applicantStatus, ApplicationStatus.underReview);
        expect(application.requiresApplicantAction, isTrue);
      },
    );

    test('every one of the 19 admin labels round-trips', () {
      const labels = [
        'Draft',
        'Submitted',
        'Received',
        'Document Verification',
        'Under Evaluation',
        'Revision Required',
        'Assessed',
        'Payment Submitted',
        'Payment Under Verification',
        'Payment Verified',
        'For Approval',
        'Approved',
        'Permit Generated',
        'Ready for Release',
        'Released',
        'Completed',
        'Rejected',
        'Cancelled',
        'Expired',
      ];
      expect(labels, hasLength(ApplicationLifecycleStatus.values.length));

      for (final label in labels) {
        final parsed = ApplicationDto.parse(_payload(lifecycleStatus: label));
        expect(parsed.lifecycleStatus!.adminLabel, label);
      }
    });

    test('a classification the LGU has not set stays null', () {
      final application = ApplicationDto.parse(_payload(classification: null));
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

    test(
      'open instruction items are counted when the server omits the total',
      () {
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
      },
    );

    test(
      'the timeline is sorted oldest-first whatever order it arrives in',
      () {
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
              {'status': 'Received', 'occurredAt': '2026-08-04T00:00:00+08:00'},
            ],
          ),
        );

        // The revision-loop rendering depends on chronology, so order is not
        // left to the server's discretion.
        expect(application.timeline.map((e) => e.status).toList(), [
          ApplicationLifecycleStatus.submitted,
          ApplicationLifecycleStatus.received,
          ApplicationLifecycleStatus.underEvaluation,
        ]);
      },
    );

    test('evaluations sort into stage order', () {
      final application = ApplicationDto.parse(
        _payload()
          ..['evaluations'] = [
            {'stage': 'OBO', 'result': 'Pending'},
            {'stage': 'Initial', 'result': 'Passed'},
            {'stage': 'Fire Safety', 'result': 'Pending'},
          ],
      );

      expect(application.evaluations.map((e) => e.stage).toList(), [
        EvaluationStage.initial,
        EvaluationStage.fireSafety,
        EvaluationStage.obo,
      ]);
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

  group('the per-document review layer reaches the model', () {
    // Everything TAB 02 built was reachable from the mock repository and from
    // nowhere else: the parser read four fields and dropped status, remarks,
    // the issuing office, the document's own expiry and the whole submission
    // history. Three screens rendered data a live server could never have
    // supplied.

    Map<String, dynamic> withDocuments(List<Object> docs) => {
      ..._payload(),
      'documents': docs,
    };

    test('status, remarks and the standard reason all arrive', () {
      final parsed = ApplicationDto.parse(
        withDocuments([
          {
            'id': 'doc-1',
            'label': 'Certified True Copy of Title',
            'fileName': 'title.pdf',
            'uploadedAt': '2026-08-04T10:00:00+08:00',
            'status': 'Rejected',
            'remarks': 'Page 3 cannot be read.',
            'reviewReason': {'code': 'illegible', 'label': 'Illegible'},
            'issuingOffice': 'Registry of Deeds',
            'issueDate': '2026-01-10T00:00:00+08:00',
            'expiryDate': '2027-01-10T00:00:00+08:00',
          },
        ]),
      );

      final doc = parsed.documents.single;
      expect(doc.status, DocumentStatus.rejected);
      expect(doc.remarks, 'Page 3 cannot be read.');
      expect(doc.reviewReason?.code, 'illegible');
      expect(doc.reviewReason?.label, 'Illegible');
      expect(doc.issuingOffice, 'Registry of Deeds');
      expect(doc.issueDate, isNotNull);
      expect(doc.expiryDate, isNotNull);
      expect(doc.needsApplicantAction, isTrue);
      expect(doc.reviewFeedback, 'Illegible — Page 3 cannot be read.');
    });

    test('an absent status means nobody has reviewed it, not a failure', () {
      final parsed = ApplicationDto.parse(
        withDocuments([
          {
            'id': 'doc-1',
            'label': 'Cedula',
            'fileName': 'cedula.pdf',
            'uploadedAt': '2026-08-04T10:00:00+08:00',
          },
        ]),
      );
      expect(parsed.documents.single.status, isNull);
      expect(parsed.documents.single.needsApplicantAction, isFalse);
    });

    test('an UNKNOWN status is a failure, because guessing is worse', () {
      // The admin's closed vocabulary. Inventing a meaning for a status is how
      // an applicant gets told their document was accepted.
      expect(
        () => ApplicationDto.parse(
          withDocuments([
            {
              'id': 'doc-1',
              'label': 'Cedula',
              'fileName': 'cedula.pdf',
              'uploadedAt': '2026-08-04T10:00:00+08:00',
              'status': 'Approved',
            },
          ]),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'an unknown review REASON is fine, because that catalogue is open',
      () {
        // The opposite rule, deliberately. An office adding a reason must not
        // crash a phone that shipped last month.
        final parsed = ApplicationDto.parse(
          withDocuments([
            {
              'id': 'doc-1',
              'label': 'Lot Plan',
              'fileName': 'plan.pdf',
              'uploadedAt': '2026-08-04T10:00:00+08:00',
              'status': 'Revision Required',
              'reviewReason': {'code': 'smudged-ink'},
            },
          ]),
        );

        final reason = parsed.documents.single.reviewReason!;
        expect(reason.code, 'smudged-ink');
        // No label sent, so it is humanised rather than left blank.
        expect(reason.label, 'Smudged ink');
      },
    );

    test('a malformed reviewReason is dropped, not fatal', () {
      for (final bad in [<String, dynamic>{}, 'illegible', 42, null]) {
        final parsed = ApplicationDto.parse(
          withDocuments([
            {
              'id': 'doc-1',
              'label': 'Lot Plan',
              'fileName': 'plan.pdf',
              'uploadedAt': '2026-08-04T10:00:00+08:00',
              'reviewReason': bad,
            },
          ]),
        );
        expect(parsed.documents.single.reviewReason, isNull, reason: '$bad');
      }
    });

    test(
      'submission history arrives oldest first, whatever order was sent',
      () {
        final parsed = ApplicationDto.parse(
          withDocuments([
            {
              'id': 'doc-1',
              'label': 'Land Title',
              'fileName': 'title-v3.pdf',
              'uploadedAt': '2026-08-04T10:00:00+08:00',
              'history': [
                {
                  'fileName': 'title-v2.pdf',
                  'submittedAt': '2026-07-20T10:00:00+08:00',
                  'status': 'Rejected',
                  'remarks': 'Still a photocopy.',
                },
                {
                  'fileName': 'title-v1.pdf',
                  'submittedAt': '2026-07-01T10:00:00+08:00',
                  'status': 'Rejected',
                  'remarks': 'Photocopy not acceptable.',
                },
              ],
            },
          ]),
        );

        final history = parsed.documents.single.history;
        expect(history.map((h) => h.fileName), [
          'title-v1.pdf',
          'title-v2.pdf',
        ]);
        expect(history.first.remarks, 'Photocopy not acceptable.');
      },
    );

    test('a history entry with no status is a submission, not a verdict', () {
      final parsed = ApplicationDto.parse(
        withDocuments([
          {
            'id': 'doc-1',
            'label': 'Land Title',
            'fileName': 'title-v2.pdf',
            'uploadedAt': '2026-08-04T10:00:00+08:00',
            'history': [
              {
                'fileName': 'title-v1.pdf',
                'submittedAt': '2026-07-01T10:00:00+08:00',
              },
            ],
          },
        ]),
      );
      expect(
        parsed.documents.single.history.single.status,
        DocumentStatus.submitted,
      );
    });
  });

  group('the payment layer reaches the model', () {
    // Same shape of gap as the documents one, found by diffing every model's
    // constructor against what this parser actually sets. TABs 06, 07 and 08
    // built partial payment, rejection reasons, the Official Receipt, the
    // collecting agency and assessment supersession — and the parser filled
    // seven of eleven fields, so all of it was mock-only.

    Map<String, dynamic> withPayment(Map<String, dynamic> payment) => {
      ..._payload(),
      'payment': payment,
    };

    Map<String, dynamic> order({
      String number = 'OP-2026-0002',
      int version = 2,
      String? status,
      String? revisionReason,
    }) => {
      'number': number,
      'assessedAt': '2026-08-12T09:00:00+08:00',
      'version': version,
      'status': ?status,
      'revisionReason': ?revisionReason,
      'fees': {
        'filing': 50000,
        'processing': 0,
        'architectural': 0,
        'structural': 0,
        'electrical': 0,
        'others': 0,
      },
    };

    test('every payment made against the assessment arrives, oldest first', () {
      final parsed = ApplicationDto.parse(
        withPayment({
          'status': 'Partially Paid',
          'orderOfPayment': order(),
          'transactions': [
            {
              'id': 'txn-2',
              'amountCentavos': 20000,
              'method': 'Bank Transfer',
              'reference': 'DEP-2',
              'status': 'Verified',
              'submittedAt': '2026-08-15T09:00:00+08:00',
              'agency': 'BFP',
              'orNumber': 'OR-2026-000123',
              'orDate': '2026-08-16T09:00:00+08:00',
              'orIssuedBy': 'City Treasurer',
            },
            {
              'id': 'txn-1',
              'amountCentavos': 10000,
              'method': 'Onsite',
              'reference': 'CTR-1',
              'status': 'Rejected',
              'submittedAt': '2026-08-13T09:00:00+08:00',
              'rejectionReason': 'Deposit slip is illegible.',
            },
          ],
        }),
      );

      final txns = parsed.payment!.transactions;
      expect(txns.map((t) => t.id), ['txn-1', 'txn-2']);

      // A rejected payment must carry its reason or the applicant is told the
      // money did not land and never why.
      expect(txns.first.rejectionReason, 'Deposit slip is illegible.');
      expect(txns.first.countsTowardBalance, isFalse);

      // The Official Receipt, never fabricated, and the office that took it.
      expect(txns.last.orNumber, 'OR-2026-000123');
      expect(txns.last.agency, CollectingAgency.bfp);
      expect(txns.last.hasOfficialReceipt, isTrue);
      expect(txns.last.countsTowardBalance, isTrue);
    });

    test('a transaction with no agency is the LGU, not a failure', () {
      // Most payments are, and an older server may not send the field.
      final parsed = ApplicationDto.parse(
        withPayment({
          'status': 'Paid',
          'orderOfPayment': order(),
          'transactions': [
            {
              'id': 'txn-1',
              'amountCentavos': 50000,
              'method': 'Onsite',
              'reference': 'CTR-1',
              'status': 'Verified',
              'submittedAt': '2026-08-13T09:00:00+08:00',
            },
          ],
        }),
      );
      expect(
        parsed.payment!.transactions.single.agency,
        CollectingAgency.oboLgu,
      );
      expect(parsed.payment!.transactions.single.orNumber, isNull);
    });

    test('an unknown collecting agency throws rather than defaulting', () {
      // Sending an applicant to the wrong cashier costs them the morning.
      expect(
        () => ApplicationDto.parse(
          withPayment({
            'status': 'Paid',
            'orderOfPayment': order(),
            'transactions': [
              {
                'id': 'txn-1',
                'amountCentavos': 50000,
                'method': 'Onsite',
                'reference': 'CTR-1',
                'status': 'Verified',
                'submittedAt': '2026-08-13T09:00:00+08:00',
                'agency': 'Barangay',
              },
            ],
          }),
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('the order carries its version, status and revision reason', () {
      // isPayable is derived from status. A parser that never set it left
      // every order looking payable, including a superseded one.
      final parsed = ApplicationDto.parse(
        withPayment({
          'status': 'Pending Verification',
          'orderOfPayment': order(
            version: 2,
            status: 'Issued',
            revisionReason: 'Floor area corrected after ocular inspection',
          ),
          'supersededOrders': [
            order(number: 'OP-2026-0001', version: 1, status: 'Superseded'),
          ],
        }),
      );

      final payment = parsed.payment!;
      expect(payment.orderOfPayment!.version, 2);
      expect(payment.orderOfPayment!.isPayable, isTrue);
      expect(
        payment.orderOfPayment!.revisionReason,
        'Floor area corrected after ocular inspection',
      );

      expect(payment.wasReassessed, isTrue);
      expect(payment.supersededOrders.single.isSuperseded, isTrue);
      expect(payment.supersededOrders.single.isPayable, isFalse);
    });

    test('an order with no status is an ordinary issued one', () {
      final parsed = ApplicationDto.parse(
        withPayment({
          'status': 'Pending Verification',
          'orderOfPayment': order(),
        }),
      );
      expect(parsed.payment!.orderOfPayment!.status, AssessmentStatus.issued);
      expect(parsed.payment!.orderOfPayment!.isPayable, isTrue);
    });

    test('adjustments arrive with what they were for', () {
      final parsed = ApplicationDto.parse(
        withPayment({
          'status': 'Paid',
          'orderOfPayment': order(),
          'adjustments': [
            {
              'id': 'adj-1',
              'type': 'Refund',
              'amountCentavos': 5000,
              'appliedAt': '2026-08-20T09:00:00+08:00',
              'reason': 'Overpayment returned.',
            },
          ],
        }),
      );
      final adj = parsed.payment!.adjustments.single;
      expect(adj.type, PaymentAdjustmentType.refund);
      expect(adj.reason, 'Overpayment returned.');
    });

    test('proof of payment parses as a document, not a bare filename', () {
      final parsed = ApplicationDto.parse(
        withPayment({
          'status': 'Pending Verification',
          'orderOfPayment': order(),
          'proof': {
            'id': 'doc-proof',
            'label': 'Deposit slip',
            'fileName': 'slip.jpg',
            'uploadedAt': '2026-08-13T09:00:00+08:00',
            'status': 'Rejected',
            'remarks': 'The reference number is not readable.',
          },
        }),
      );
      final proof = parsed.payment!.proof!;
      expect(proof.label, 'Deposit slip');
      expect(proof.status, DocumentStatus.rejected);
      expect(proof.needsApplicantAction, isTrue);
    });

    test('an assessment with none of it still parses', () {
      final parsed = ApplicationDto.parse(
        withPayment({'status': 'Not Yet Available'}),
      );
      expect(parsed.payment!.transactions, isEmpty);
      expect(parsed.payment!.adjustments, isEmpty);
      expect(parsed.payment!.supersededOrders, isEmpty);
      expect(parsed.payment!.proof, isNull);
    });
  });

  test('every payment status the app models can arrive on the wire', () {
    // The audit that found the gap above also found this: the parser knew four
    // of the five. 'Partially Paid' failed as malformed, and because payment is
    // parsed inside parse(), the WHOLE application failed to load -- an
    // applicant who had paid some of what they owed could not open their own
    // record.
    //
    // Asserted over the enum rather than a hand-written list, so a sixth state
    // added to the model fails here instead of at an applicant.
    for (final status in PaymentAssessmentStatus.values) {
      final parsed = ApplicationDto.parse({
        ..._payload(),
        'payment': {'status': status.label},
      });
      expect(parsed.payment!.status, status, reason: status.label);
    }
  });
}
