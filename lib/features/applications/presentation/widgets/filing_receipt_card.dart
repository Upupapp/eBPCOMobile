import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/filing_receipt.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/cards/app_card.dart';

/// What the office received, shown to the citizen who sent it.
///
/// The confirmation screen told them a reference number and nothing else, so
/// "Submitted!" was an assertion with no evidence under it — and twice it was
/// an assertion over machinery that was not running. This card is the evidence:
/// the site the office holds, how many of the attached files it took, and how
/// many answers travelled with them.
///
/// It reports shortfalls rather than hiding them. A filing that reached the
/// office with none of its attachments still says Submitted at the top, which
/// is true; this is where it stops being the whole truth.
class FilingReceiptCard extends StatelessWidget {
  final FilingReceipt receipt;

  const FilingReceiptCard({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What the office received', style: AppTypography.sectionTitle),
          const SizedBox(height: 2),
          // Named so the citizen can weigh it. A count this app made up would
          // be worth nothing to them; these came back from the office.
          Text(
            'Confirmed by the office, not by this app.',
            style: AppTypography.helper,
          ),
          const SizedBox(height: AppSpacing.md),

          if (receipt.location != null)
            _ReceiptRow(
              icon: Icons.place_outlined,
              label: 'Site on record',
              value: receipt.location!,
            ),

          _ReceiptRow(
            icon: Icons.attach_file,
            label: 'Attachments held',
            value: receipt.attachmentsOffered == 0
                ? 'None attached'
                : '${receipt.attachmentsAccepted} of '
                      '${receipt.attachmentsOffered}',
            // The disclosure the old screen had no place for. Amber rather
            // than red: the filing is real and the reference number is real,
            // and the citizen needs to act, not to panic.
            warning: receipt.attachmentsAreShort
                ? 'The office did not receive '
                      '${receipt.attachmentsOffered - receipt.attachmentsAccepted} '
                      'of your files. Open the application and attach them '
                      'again, or bring them to the counter.'
                : null,
          ),

          _ReceiptRow(
            icon: Icons.assignment_outlined,
            label: 'Answers sent',
            value: receipt.carriesNoAnswers ? 'None' : '${receipt.answersSent}',
            warning: receipt.carriesNoAnswers
                ? 'None of what you typed reached the office. Ask at the '
                      'counter before the assessment starts.'
                : null,
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? warning;

  const _ReceiptRow({
    required this.icon,
    required this.label,
    required this.value,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wraps rather than a Row with a fixed trailing: at 2.0x text scale
          // a site line is several lines long, and this column has overflowed
          // in every earlier form it took.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.caption),
                    Text(value, style: AppTypography.body),
                  ],
                ),
              ),
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.statusPendingBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                warning!,
                style: AppTypography.helper.copyWith(
                  color: AppColors.statusPending,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
