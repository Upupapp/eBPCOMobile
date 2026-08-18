import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/application_model.dart';
import '../../../core/models/order_of_payment.dart';
import '../../../core/models/payment_assessment_model.dart';
import '../../../core/providers/applications_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
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
            _FeeBreakdown(order: order),
            const SizedBox(height: AppSpacing.lg),
            _StatusPanel(payment: payment!),
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

  const _FeeBreakdown({required this.order});

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
          Row(
            children: [
              Expanded(
                child: Text('Total', style: AppTypography.cardTitle),
              ),
              Text(order.total.formatted, style: AppTypography.cardTitle),
            ],
          ),
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
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.line.label,
                            style: AppTypography.body,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.help_outline,
                          size: 15,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.line.amount.formatted,
                    style: AppTypography.bodyStrong,
                  ),
                ],
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
