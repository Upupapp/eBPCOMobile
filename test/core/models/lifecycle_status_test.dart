import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';

void main() {
  test('every one of the 19 admin states is represented', () {
    expect(ApplicationLifecycleStatus.values, hasLength(19));
  });

  test('every state has a label, sub-line, and applicant projection', () {
    for (final status in ApplicationLifecycleStatus.values) {
      expect(status.adminLabel, isNotEmpty, reason: '$status has no label');
      expect(
        status.applicantSubLine,
        isNotEmpty,
        reason: '$status has no sub-line',
      );
      // Exhaustive switches make this total, but asserting it keeps a future
      // added state from silently defaulting.
      expect(status.applicantStatus, isA<ApplicationStatus>());
    }
  });

  test('the projection matches the admin LIFECYCLE_TO_MOBILE_LABEL exactly', () {
    const expected = <ApplicationLifecycleStatus, ApplicationStatus>{
      ApplicationLifecycleStatus.draft: ApplicationStatus.draft,
      ApplicationLifecycleStatus.submitted: ApplicationStatus.submitted,
      ApplicationLifecycleStatus.received: ApplicationStatus.submitted,
      ApplicationLifecycleStatus.documentVerification:
          ApplicationStatus.underReview,
      ApplicationLifecycleStatus.underEvaluation: ApplicationStatus.underReview,
      ApplicationLifecycleStatus.revisionRequired:
          ApplicationStatus.underReview,
      ApplicationLifecycleStatus.assessed:
          ApplicationStatus.paymentVerification,
      ApplicationLifecycleStatus.paymentSubmitted:
          ApplicationStatus.paymentVerification,
      ApplicationLifecycleStatus.paymentUnderVerification:
          ApplicationStatus.paymentVerification,
      ApplicationLifecycleStatus.paymentVerified:
          ApplicationStatus.paymentVerification,
      ApplicationLifecycleStatus.forApproval:
          ApplicationStatus.paymentVerification,
      ApplicationLifecycleStatus.approved: ApplicationStatus.approved,
      ApplicationLifecycleStatus.permitGenerated: ApplicationStatus.approved,
      ApplicationLifecycleStatus.readyForRelease: ApplicationStatus.released,
      ApplicationLifecycleStatus.released: ApplicationStatus.released,
      ApplicationLifecycleStatus.completed: ApplicationStatus.released,
      ApplicationLifecycleStatus.rejected: ApplicationStatus.rejected,
      ApplicationLifecycleStatus.cancelled: ApplicationStatus.rejected,
      ApplicationLifecycleStatus.expired: ApplicationStatus.rejected,
    };

    for (final entry in expected.entries) {
      expect(
        entry.key.applicantStatus,
        entry.value,
        reason: '${entry.key} must project onto ${entry.value}',
      );
    }
    expect(expected.keys.toSet(), ApplicationLifecycleStatus.values.toSet());
  });

  test('exactly three states are waiting on the applicant', () {
    final waiting = ApplicationLifecycleStatus.values
        .where((s) => s.requiresApplicantAction)
        .toSet();

    expect(waiting, {
      ApplicationLifecycleStatus.revisionRequired,
      ApplicationLifecycleStatus.assessed,
      ApplicationLifecycleStatus.readyForRelease,
    });
  });

  test('two of those three hide behind a passive headline', () {
    // The reason requiresApplicantAction cannot be derived from the applicant
    // status: these two look identical to states where the office is working.
    expect(
      ApplicationLifecycleStatus.revisionRequired.applicantStatus,
      ApplicationLifecycleStatus.underEvaluation.applicantStatus,
    );
    expect(
      ApplicationLifecycleStatus.assessed.applicantStatus,
      ApplicationLifecycleStatus.paymentVerified.applicantStatus,
    );
  });

  test('terminal states are the four the admin declares terminal', () {
    final terminal = ApplicationLifecycleStatus.values
        .where((s) => s.isTerminal)
        .toSet();

    expect(terminal, {
      ApplicationLifecycleStatus.completed,
      ApplicationLifecycleStatus.rejected,
      ApplicationLifecycleStatus.cancelled,
      ApplicationLifecycleStatus.expired,
    });
  });

  test('in-flight excludes drafts and terminal states', () {
    expect(ApplicationLifecycleStatus.draft.isInFlight, isFalse);
    expect(ApplicationLifecycleStatus.completed.isInFlight, isFalse);
    expect(ApplicationLifecycleStatus.underEvaluation.isInFlight, isTrue);
    expect(ApplicationLifecycleStatus.assessed.isInFlight, isTrue);
  });

  test('the happy-path sequence omits the revision loop', () {
    expect(
      lifecycleSequence,
      isNot(contains(ApplicationLifecycleStatus.revisionRequired)),
    );
    // And omits the terminal exits, which are reachable from most states.
    for (final terminal in [
      ApplicationLifecycleStatus.rejected,
      ApplicationLifecycleStatus.cancelled,
      ApplicationLifecycleStatus.expired,
    ]) {
      expect(lifecycleSequence, isNot(contains(terminal)));
    }
  });
}
