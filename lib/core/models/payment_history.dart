import 'application_model.dart';
import 'money.dart';
import 'payment_assessment_model.dart';

/// One settled or in-flight payment, flattened out of its application.
///
/// Payments live on applications, but an applicant looking at their records
/// is thinking in transactions — "what did I pay this year, and for what" —
/// not in applications. This is that view.
class PaymentHistoryEntry {
  final String applicationId;
  final String applicationNumber;
  final String businessId;
  final String businessName;
  final String permitType;
  final String orderOfPaymentNumber;
  final PesoAmount amount;
  final PaymentAssessmentStatus status;
  final PaymentMethod? method;
  final String? referenceNumber;
  final String? officialReceiptNumber;

  /// When the applicant reported paying.
  final DateTime? submittedAt;

  /// When the Treasurer's Office confirmed it.
  final DateTime? verifiedAt;

  /// When this transaction was assessed — always present, and the date the
  /// history is grouped by, since it is the only one every row has.
  final DateTime assessedAt;

  const PaymentHistoryEntry({
    required this.applicationId,
    required this.applicationNumber,
    required this.businessId,
    required this.businessName,
    required this.permitType,
    required this.orderOfPaymentNumber,
    required this.amount,
    required this.status,
    required this.assessedAt,
    this.method,
    this.referenceNumber,
    this.officialReceiptNumber,
    this.submittedAt,
    this.verifiedAt,
  });

  /// The year this transaction belongs to, for filtering.
  int get year => assessedAt.year;

  bool get isSettled => status == PaymentAssessmentStatus.paid;

  /// Builds the history from the applicant's applications.
  ///
  /// Only assessed applications appear. An application with no Order of
  /// Payment has no transaction to report, and listing it with a blank amount
  /// would imply a charge that does not exist.
  static List<PaymentHistoryEntry> from(List<ApplicationModel> applications) {
    final entries = <PaymentHistoryEntry>[];

    for (final application in applications) {
      final payment = application.payment;
      final order = payment?.orderOfPayment;
      if (payment == null || order == null) continue;

      entries.add(
        PaymentHistoryEntry(
          applicationId: application.id,
          applicationNumber: application.applicationNumber,
          businessId: application.businessId,
          businessName: application.businessName,
          permitType: application.permitTypeLabel ?? application.type.label,
          orderOfPaymentNumber: order.number,
          amount: order.total,
          status: payment.status,
          method: payment.method,
          referenceNumber: payment.referenceNumber,
          officialReceiptNumber: payment.officialReceiptNumber,
          submittedAt: payment.submittedAt,
          verifiedAt: payment.verifiedAt,
          assessedAt: order.assessedAt,
        ),
      );
    }

    // Newest first — an applicant checking their records is almost always
    // looking for something recent.
    entries.sort((a, b) => b.assessedAt.compareTo(a.assessedAt));
    return entries;
  }
}

/// Renders payment history as CSV.
///
/// CSV rather than a formatted receipt because the destination is almost
/// always a spreadsheet or an accountant, and because it opens everywhere
/// without the app having to render a document. An official receipt remains
/// the LGU's to issue — nothing here is a substitute for one, and the export
/// says so in its own header.
class PaymentHistoryCsv {
  const PaymentHistoryCsv._();

  static const _columns = [
    'Assessed',
    'Business',
    'Permit type',
    'Application',
    'O.P. number',
    'Amount (PHP)',
    'Status',
    'Method',
    'Reference',
    'Official receipt',
    'Submitted',
    'Verified',
  ];

  static String render(
    List<PaymentHistoryEntry> entries, {
    required DateTime generatedAt,
  }) {
    final buffer = StringBuffer()
      // A note rather than a bare table, so a printed copy cannot be mistaken
      // for something the LGU issued.
      ..writeln(
        '# eBPCO Mobile payment record, exported '
        '${_date(generatedAt)}. Not an official receipt.',
      )
      ..writeln(_columns.map(_escape).join(','));

    for (final entry in entries) {
      buffer.writeln(
        [
          _date(entry.assessedAt),
          entry.businessName,
          entry.permitType,
          entry.applicationNumber,
          entry.orderOfPaymentNumber,
          // Bare decimal, not "PHP 1,234.56": a spreadsheet must be able to
          // sum this column without the reader stripping symbols first.
          entry.amount.formattedBare.replaceAll(',', ''),
          entry.status.label,
          entry.method?.label ?? '',
          entry.referenceNumber ?? '',
          entry.officialReceiptNumber ?? '',
          entry.submittedAt == null ? '' : _date(entry.submittedAt!),
          entry.verifiedAt == null ? '' : _date(entry.verifiedAt!),
        ].map(_escape).join(','),
      );
    }

    return buffer.toString();
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  /// RFC 4180 quoting. Business names carry commas often enough ("Juan's
  /// Merchandise, Inc.") that an unquoted export would silently corrupt the
  /// column alignment of exactly the rows someone cares about.
  static String _escape(String value) {
    final needsQuoting =
        value.contains(',') || value.contains('"') || value.contains('\n');
    if (!needsQuoting) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
