import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/money.dart';
import '../../../core/models/payment_assessment_model.dart';
import '../../../core/models/payment_history.dart';
import '../../../core/providers/applications_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/layout/amount_row.dart';
import '../../../shared/widgets/states/empty_state.dart';

/// Every payment across every application, filterable by business and year.
///
/// The Payments tab answers "what do I owe now". This answers "what have I
/// paid" — a different question, asked at a different time, usually by
/// someone assembling records for an accountant or a renewal.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  int? _year;
  String? _businessId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationsProvider>();
    final all = PaymentHistoryEntry.from(provider.applications);

    final years = (all.map((e) => e.year).toSet().toList()..sort()).reversed
        .toList();
    final businesses = {
      for (final entry in all) entry.businessId: entry.businessName,
    };

    final filtered = all
        .where((e) => _year == null || e.year == _year)
        .where((e) => _businessId == null || e.businessId == _businessId)
        .toList();

    // Only settled payments are totalled. Summing what is merely assessed
    // would overstate what the applicant has actually spent.
    final settled = filtered.where((e) => e.isSettled).toList();
    final total = sumPesos(settled.map((e) => e.amount));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            tooltip: 'Export as CSV',
            icon: const Icon(Icons.ios_share),
            onPressed: filtered.isEmpty
                ? null
                : () => _export(context, filtered),
          ),
        ],
      ),
      body: SafeArea(
        child: all.isEmpty
            ? const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No payments yet',
                message:
                    'Once the office assesses an application, the transaction '
                    'appears here and stays for your records.',
              )
            : Column(
                children: [
                  _Filters(
                    years: years,
                    businesses: businesses,
                    selectedYear: _year,
                    selectedBusinessId: _businessId,
                    onYear: (value) => setState(() => _year = value),
                    onBusiness: (value) => setState(() => _businessId = value),
                  ),
                  _Total(total: total, settledCount: settled.length),
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.filter_alt_off_outlined,
                            title: 'Nothing in this selection',
                            message: 'Try a different year or business.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(
                              AppConstants.screenPaddingHorizontal,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) =>
                                _HistoryTile(entry: filtered[index]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    List<PaymentHistoryEntry> entries,
  ) async {
    final csv = PaymentHistoryCsv.render(entries, generatedAt: DateTime.now());
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;

    // Clipboard rather than a share sheet: sharing needs a platform plugin
    // this app does not carry, and a copied CSV pastes straight into a
    // spreadsheet or an email, which is where these records are going.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${entries.length} transaction(s) copied as CSV. Paste into a '
          'spreadsheet or email.',
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final List<int> years;
  final Map<String, String> businesses;
  final int? selectedYear;
  final String? selectedBusinessId;
  final ValueChanged<int?> onYear;
  final ValueChanged<String?> onBusiness;

  const _Filters({
    required this.years,
    required this.businesses,
    required this.selectedYear,
    required this.selectedBusinessId,
    required this.onYear,
    required this.onBusiness,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenPaddingHorizontal,
        AppSpacing.md,
        AppConstants.screenPaddingHorizontal,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int?>(
              initialValue: selectedYear,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Year',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All years')),
                for (final year in years)
                  DropdownMenuItem(value: year, child: Text('$year')),
              ],
              onChanged: onYear,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: selectedBusinessId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Business',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                for (final entry in businesses.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: onBusiness,
            ),
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final PesoAmount total;
  final int settledCount;

  const _Total({required this.total, required this.settledCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppConstants.screenPaddingHorizontal,
        AppSpacing.md,
        AppConstants.screenPaddingHorizontal,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: AmountRow(
        label: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total paid', style: AppTypography.helper),
            Text(total.formatted, style: AppTypography.cardTitle),
          ],
        ),
        amount: Text(
          settledCount == 1
              ? '1 verified payment'
              : '$settledCount verified payments',
          style: AppTypography.helper,
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final PaymentHistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('MMM d, yyyy');

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: InkWell(
        onTap: () => context.push('/applications/${entry.applicationId}/pay'),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppConstants.minTouchTarget,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountRow(
                label: Text(entry.permitType, style: AppTypography.cardTitle),
                amount: Text(
                  entry.amount.formatted,
                  style: AppTypography.bodyStrong,
                ),
              ),
              Text(entry.businessName, style: AppTypography.bodyMuted),
              Text(
                '${entry.applicationNumber} · O.P. '
                '${entry.orderOfPaymentNumber}',
                style: AppTypography.helper,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: entry.status.backgroundColor,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusPill,
                      ),
                    ),
                    child: Text(
                      entry.status == PaymentAssessmentStatus.notYetAvailable
                          ? 'Unpaid'
                          : entry.status.label,
                      style: AppTypography.helper.copyWith(
                        color: entry.status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Assessed ${format.format(entry.assessedAt)}',
                      style: AppTypography.helper,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (entry.officialReceiptNumber != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Official receipt ${entry.officialReceiptNumber}',
                  style: AppTypography.helper,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
