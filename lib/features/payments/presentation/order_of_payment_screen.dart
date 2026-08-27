import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/contract/admin_vocabulary.dart';
import '../../../core/models/application_model.dart';
import '../../../core/models/order_of_payment.dart';
import '../../../core/models/payment_assessment_model.dart';
import '../../../core/providers/applications_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/layout/amount_row.dart';
import '../../../shared/widgets/states/empty_state.dart';
import 'widgets/proof_of_payment_sheet.dart';

/// The Order of Payment, itemised, plus how to settle it.
///
/// Everything on this screen traces to the LGU's assessment. Where no
/// assessment exists the screen says so and explains what triggers one; it
/// does not show a zero, an estimate, or a blank.
class OrderOfPaymentScreen extends StatelessWidget {
  final String applicationId;

  const OrderOfPaymentScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationsProvider>();
    final application = provider.byId(applicationId);
    final payment = application?.payment;
    final order = payment?.orderOfPayment;

    if (application == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order of Payment')),
        body: const EmptyState(
          icon: Icons.search_off_outlined,
          title: 'Application not found',
          message: 'This application could not be found on this device.',
        ),
      );
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order of Payment')),
        body: const EmptyState(
          icon: Icons.hourglass_empty_outlined,
          title: 'Not yet available',
          message:
              'Fees are assessed after your documents pass evaluation. Once '
              'the Office of the Building Official issues your Order of '
              'Payment, the full breakdown appears here.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order of Payment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.screenPaddingHorizontal),
          children: [
            _OrderHeader(application: application, order: order),
            const SizedBox(height: AppSpacing.lg),
            _FeeBreakdown(order: order, payment: payment),
            const SizedBox(height: AppSpacing.lg),
            if (payment!.wasReassessed) ...[
              const SizedBox(height: AppSpacing.lg),
              _Reassessed(payment: payment),
            ],
            if (payment.receipts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _Receipts(payments: payment.receipts),
            ],
            if (payment.adjustments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _Adjustments(adjustments: payment.adjustments),
            ],
            if (payment.rejectedTransactions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _RejectedPayments(payments: payment.rejectedTransactions),
            ],
            _StatusPanel(payment: payment),
            const SizedBox(height: AppSpacing.lg),
            if (payment.status == PaymentAssessmentStatus.notYetAvailable ||
                payment.status == PaymentAssessmentStatus.overdue)
              _PayActions(applicationId: applicationId, order: order),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  final ApplicationModel application;
  final OrderOfPayment order;

  const _OrderHeader({required this.application, required this.order});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('O.P. No. ${order.number}', style: AppTypography.cardTitle),
          Text(
            application.permitTypeLabel ?? application.type.label,
            style: AppTypography.bodyMuted,
          ),
          Text(application.applicationNumber, style: AppTypography.helper),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Assessed ${format.format(order.assessedAt)}'
            '${order.assessedBy != null ? ' by ${order.assessedBy}' : ''}',
            style: AppTypography.helper,
          ),
          if (order.dueDate != null)
            Text(
              'Pay on or before ${format.format(order.dueDate!)}',
              style: AppTypography.helper.copyWith(
                color: AppColors.statusRejected,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _FeeBreakdown extends StatelessWidget {
  final OrderOfPayment order;
  final PaymentAssessmentModel? payment;

  const _FeeBreakdown({required this.order, this.payment});

  @override
  Widget build(BuildContext context) {
    // A total that does not equal its own lines is a hard error, never a
    // quietly rounded figure — someone is about to pay from this screen.
    if (!order.isConsistent) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.statusRejectedBg,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(color: AppColors.statusRejected),
        ),
        child: Text(
          'This Order of Payment could not be displayed: its line items do '
          'not add up to its total. Please contact the Office of the Building '
          'Official before paying.',
          style: AppTypography.body.copyWith(color: AppColors.statusRejected),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in order.fees.lines) ...[
            _FeeRow(line: line),
            const Divider(height: AppSpacing.xl),
          ],
          AmountRow(
            label: Text('Total', style: AppTypography.cardTitle),
            amount: Text(order.total.formatted, style: AppTypography.cardTitle),
          ),
          // Shown only once something has actually been accepted. A "Paid:
          // ₱0.00 / Balance: ₱x" on an untouched assessment is noise dressed
          // as information.
          if ((payment?.amountPaid.centavos ?? 0) > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            AmountRow(
              label: Text('Paid', style: AppTypography.body),
              amount: Text(
                payment!.amountPaid.formatted,
                style: AppTypography.bodyStrong,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AmountRow(
              label: Text('Balance due', style: AppTypography.cardTitle),
              amount: Text(
                payment!.balanceDue?.formatted ?? '—',
                style: AppTypography.cardTitle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeeRow extends StatefulWidget {
  final FeeLine line;

  const _FeeRow({required this.line});

  @override
  State<_FeeRow> createState() => _FeeRowState();
}

class _FeeRowState extends State<_FeeRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${widget.line.label}, ${widget.line.amount.formatted}. '
          'Tap for what this fee covers.',
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountRow(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(widget.line.label, style: AppTypography.body),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.help_outline,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                amount: Text(
                  widget.line.amount.formatted,
                  style: AppTypography.bodyStrong,
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(widget.line.explainer, style: AppTypography.helper),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final PaymentAssessmentModel payment;

  const _StatusPanel({required this.payment});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');
    final status = payment.status;

    String body;
    switch (status) {
      case PaymentAssessmentStatus.notYetAvailable:
        body = 'Not yet paid.';
      case PaymentAssessmentStatus.pending:
        body =
            'Submitted${payment.submittedAt != null ? ' ${format.format(payment.submittedAt!)}' : ''}'
            '${payment.method != null ? ' by ${payment.method!.label}' : ''}. '
            'The Treasurer’s Office is verifying it.';
      case PaymentAssessmentStatus.paid:
        body =
            'Verified'
            '${payment.verifiedAt != null ? ' ${format.format(payment.verifiedAt!)}' : ''}.'
            '${payment.officialReceiptNumber != null ? ' Official receipt ${payment.officialReceiptNumber}.' : ''}';
      case PaymentAssessmentStatus.partiallyPaid:
        final balance = payment.balanceDue;
        body =
            'Part of this assessment has been settled. '
            '${payment.amountPaid.formatted} received'
            '${balance != null ? ', ${balance.formatted} still due' : ''}.';
      case PaymentAssessmentStatus.overdue:
        body =
            'Past due. Unpaid applications may lapse — settle this as soon as '
            'you can.';
    }

    final label = status == PaymentAssessmentStatus.notYetAvailable
        ? 'Unpaid'
        : status.label;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.cardTitle.copyWith(color: status.color),
          ),
          const SizedBox(height: 2),
          Text(body, style: AppTypography.body),
          if (payment.referenceNumber != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reference ${payment.referenceNumber}',
              style: AppTypography.helper,
            ),
          ],
        ],
      ),
    );
  }
}

class _PayActions extends StatelessWidget {
  final String applicationId;
  final OrderOfPayment order;

  const _PayActions({required this.applicationId, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How to pay', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.md),

        // Only the two channels the LGU actually accepts. Offering an
        // unaccepted channel would strand an applicant's money.
        const _MethodCard(
          icon: Icons.account_balance_outlined,
          title: 'Bank Transfer',
          body:
              'Deposit or transfer to the City Treasurer’s account, then '
              'submit your reference number and a photo of the deposit slip '
              'for verification.',
        ),
        const _MethodCard(
          icon: Icons.storefront_outlined,
          title: 'Onsite',
          body:
              'Pay at the City Treasurer’s Office cashier and keep your '
              'official receipt. Bring a printed copy of this Order of '
              'Payment.',
        ),

        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Submit proof of payment',
          icon: Icons.upload_file_outlined,
          onPressed: () =>
              showProofOfPaymentSheet(context, applicationId: applicationId),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.secondaryBlue),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(body, style: AppTypography.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Payments the office turned back, and why.
///
/// Before this the applicant could see that a payment was "Pending
/// Verification" and then, at some point, that it was not. The reason the
/// office recorded against it had nowhere to appear, so the applicant could
/// not tell whether to send the same proof again, a different one, or a
/// different amount.
class _RejectedPayments extends StatelessWidget {
  final List<PaymentTransactionRecord> payments;

  const _RejectedPayments({required this.payments});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statusRejectedBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payments.length == 1
                ? 'A payment was not accepted'
                : '${payments.length} payments were not accepted',
            style: AppTypography.cardTitle.copyWith(
              color: AppColors.statusRejected,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final payment in payments) ...[
            AmountRow(
              label: Text(
                '${payment.method.label} · ${format.format(payment.submittedAt)}',
                style: AppTypography.body,
              ),
              amount: Text(
                payment.amount.formatted,
                style: AppTypography.bodyStrong,
              ),
            ),
            if (payment.reference.trim().isNotEmpty)
              Text('Ref. ${payment.reference}', style: AppTypography.helper),
            if (payment.rejectionReason != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  payment.rejectionReason!,
                  style: AppTypography.body,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            'This amount has not been credited to your assessment.',
            style: AppTypography.helper,
          ),
        ],
      ),
    );
  }
}

/// The Official Receipts issued against this assessment.
///
/// An OR is the applicant's proof that a government office took their money.
/// Before this the app referenced an OR number in four wizard steps and one
/// notification payload while having no field to hold one, so the number an
/// applicant would actually be asked to quote lived nowhere.
class _Receipts extends StatelessWidget {
  final List<PaymentTransactionRecord> payments;

  const _Receipts({required this.payments});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statusApprovedBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payments.length == 1 ? 'Official Receipt' : 'Official Receipts',
            style: AppTypography.cardTitle.copyWith(
              color: AppColors.statusApproved,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final payment in payments) ...[
            Semantics(
              label: 'Official receipt number ${payment.orNumber}',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      payment.orNumber!,
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  // The applicant is asked to quote this at a counter, so it
                  // has to leave the phone without being retyped.
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 20),
                    tooltip: 'Copy receipt number',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: payment.orNumber!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt number copied.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            Text(
              [
                payment.amount.formatted,
                if (payment.orDate != null) format.format(payment.orDate!),
                payment.agency.wire,
              ].join(' · '),
              style: AppTypography.helper,
            ),
            if (payment.orIssuedBy != null)
              Text(
                'Issued by ${payment.orIssuedBy}',
                style: AppTypography.helper,
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Corrections the office applied to what was recorded.
class _Adjustments extends StatelessWidget {
  final List<PaymentAdjustmentRecord> adjustments;

  const _Adjustments({required this.adjustments});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Adjustments', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          for (final adjustment in adjustments) ...[
            AmountRow(
              label: Text(
                '${adjustment.type.wire} · '
                '${format.format(adjustment.appliedAt)}',
                style: AppTypography.body,
              ),
              amount: Text(
                adjustment.amount.formatted,
                style: AppTypography.bodyStrong,
              ),
            ),
            if (adjustment.reason != null)
              Text(adjustment.reason!, style: AppTypography.helper),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

/// Says that the assessment was replaced, and what it replaced.
///
/// The office does not edit an issued assessment — a correction builds a new
/// version and supersedes the old one. Without this the applicant sees a total
/// that has silently changed since they last looked, which reads as an error
/// in the app rather than a decision by the office.
class _Reassessed extends StatelessWidget {
  final PaymentAssessmentModel payment;

  const _Reassessed({required this.payment});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');
    final current = payment.orderOfPayment;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This assessment was reassessed',
            style: AppTypography.cardTitle.copyWith(
              color: AppColors.statusPending,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            current == null
                ? 'A new Order of Payment is being prepared.'
                : 'Order of Payment ${current.number} '
                      '(version ${current.version}) replaces what you were '
                      'shown before. Pay against this one.',
            style: AppTypography.body,
          ),
          if (current?.revisionReason != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                current!.revisionReason!,
                style: AppTypography.bodyMuted,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text('Replaced', style: AppTypography.label),
          for (final order in payment.supersededOrders)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: AmountRow(
                label: Text(
                  'v${order.version} · ${format.format(order.assessedAt)}',
                  style: AppTypography.helper,
                ),
                amount: Text(
                  order.total.formatted,
                  style: AppTypography.helper,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
