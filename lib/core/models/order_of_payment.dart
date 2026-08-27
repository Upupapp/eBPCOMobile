import '../contract/admin_vocabulary.dart';
import 'money.dart';

/// One chargeable line on an Order of Payment.
class FeeLine {
  final String label;
  final PesoAmount amount;

  /// Plain-language note on what the fee covers.
  ///
  /// Present on every line because the most common anxiety an applicant
  /// brings to an LGU counter is not the size of a fee but whether it is a
  /// real one. A charge the app can explain is a charge the applicant can
  /// check.
  final String explainer;

  const FeeLine({
    required this.label,
    required this.amount,
    required this.explainer,
  });
}

/// The assessed fees, in the six categories the web admin's
/// `AssessmentFeeCentavos` defines. Every value is whole centavos.
class AssessmentFees {
  final int filing;
  final int processing;
  final int architectural;
  final int structural;
  final int electrical;
  final int others;

  const AssessmentFees({
    this.filing = 0,
    this.processing = 0,
    this.architectural = 0,
    this.structural = 0,
    this.electrical = 0,
    this.others = 0,
  });

  List<FeeLine> get lines => [
    FeeLine(
      label: 'Filing fee',
      amount: PesoAmount(filing),
      explainer:
          'Charged when the Office of the Building Official accepts your '
          'application for processing.',
    ),
    FeeLine(
      label: 'Processing fee',
      amount: PesoAmount(processing),
      explainer:
          'Covers evaluation of your application across the reviewing '
          'offices.',
    ),
    FeeLine(
      label: 'Architectural fee',
      amount: PesoAmount(architectural),
      explainer:
          'Assessed on the architectural works in your plans, under the '
          'schedule of fees of the National Building Code.',
    ),
    FeeLine(
      label: 'Civil / structural fee',
      amount: PesoAmount(structural),
      explainer:
          'Assessed on the structural works in your plans, under the schedule '
          'of fees of the National Building Code.',
    ),
    FeeLine(
      label: 'Electrical fee',
      amount: PesoAmount(electrical),
      explainer:
          'Assessed on the electrical works in your plans, under the schedule '
          'of fees of the National Building Code.',
    ),
    FeeLine(
      label: 'Other fees',
      amount: PesoAmount(others),
      explainer:
          'Any remaining charges assessed by the Office of the Building '
          'Official for this application.',
    ),
  ].where((line) => !line.amount.isZero).toList();

  /// Exact, because every addend is an integer number of centavos.
  PesoAmount get total => PesoAmount(
    filing + processing + architectural + structural + electrical + others,
  );
}

/// The LGU's official assessment — the only legitimate source of an amount
/// due.
///
/// The app never estimates a figure the LGU has not assessed. Where no Order
/// of Payment exists the correct state is "Not Yet Available" with an
/// explanation of what triggers assessment, not a zero and not a guess.
class OrderOfPayment {
  final String number;
  final DateTime assessedAt;
  final String? assessedBy;
  final AssessmentFees fees;

  /// Last day to pay before the assessment is treated as overdue.
  final DateTime? dueDate;

  /// Which version of the assessment this is, counting from 1.
  ///
  /// The office does not edit an issued assessment. A correction after
  /// issuance builds a new version and marks the old one superseded, so the
  /// figures an applicant was shown before are still the figures they were
  /// shown — which matters if they paid against them.
  final int version;

  /// Where this version stands. `superseded` is the one that changes what the
  /// applicant should do: a superseded assessment is not payable, and showing
  /// it as though it were invites payment against a figure the office has
  /// replaced.
  final AssessmentStatus status;

  /// Why this version replaced the one before it, when the office said.
  final String? revisionReason;

  const OrderOfPayment({
    required this.number,
    required this.assessedAt,
    required this.fees,
    this.assessedBy,
    this.dueDate,
    this.version = 1,
    this.status = AssessmentStatus.issued,
    this.revisionReason,
  });

  /// Whether this is the version the applicant should pay against.
  bool get isPayable =>
      status != AssessmentStatus.superseded &&
      status != AssessmentStatus.voided &&
      status != AssessmentStatus.draft;

  bool get isSuperseded => status == AssessmentStatus.superseded;

  PesoAmount get total => fees.total;

  /// True when the rendered line items do not add up to the rendered total.
  ///
  /// Cannot happen while [total] is derived, and is checked anyway: if a
  /// server-supplied total is ever introduced alongside the lines, a
  /// disagreement must surface as an error rather than be quietly rounded
  /// away on a screen someone is about to pay from.
  bool get isConsistent =>
      sumPesos(fees.lines.map((line) => line.amount)) == total;
}
