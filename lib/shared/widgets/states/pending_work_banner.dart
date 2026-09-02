import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/sync/queued_operation.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// What this device is still holding on the citizen's behalf.
///
/// `SyncProvider` has counted queued work, flushed it on resume and recorded
/// the outcome since it was written, and **not one widget read any of it.**
/// Four getters — `pendingCount`, `hasPendingWork`, `isFlushing`,
/// `lastOutcome` — with no reader outside their own file. The comment on
/// `pendingCount` says "Shown as Queued, never as Submitted — the applicant is
/// owed the difference", and it was shown as neither.
///
/// So a citizen whose upload failed on a rural connection had their file kept,
/// retried and sent with no sign any of it happened, and no way to ask.
///
/// Renders nothing when there is nothing waiting. This must not become a
/// permanent fixture that people learn to ignore.
class PendingWorkBanner extends StatelessWidget {
  const PendingWorkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    if (!sync.hasPendingWork) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 18,
                color: AppColors.statusPending,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Waiting to reach the office',
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.statusPending,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_describe(sync.pendingByKind), style: AppTypography.body),
          const SizedBox(height: 4),
          // The sentence the whole banner exists for. Everything else here is
          // detail; this is the part that stops "the app has it" being read as
          // "the office has it".
          Text(
            'The office does not have these yet. They are kept on this phone '
            'and sent when you are back on a connection.',
            style: AppTypography.helper,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: sync.isFlushing ? null : () => sync.flush(),
              child: Text(sync.isFlushing ? 'Sending…' : 'Try now'),
            ),
          ),
        ],
      ),
    );
  }

  /// Named in the citizen's terms, not the queue's.
  ///
  /// A count with no noun tells them nothing they can act on: whether to stay
  /// on wifi, or to go to the counter, depends entirely on what is waiting.
  static String _describe(Map<QueuedOperationKind, int> byKind) {
    final parts = <String>[];
    for (final kind in QueuedOperationKind.values) {
      final count = byKind[kind] ?? 0;
      if (count == 0) continue;
      parts.add('$count ${_noun(kind, count)}');
    }
    if (parts.isEmpty) return 'Some items are waiting to be sent.';
    if (parts.length == 1) return '${parts.single} waiting to be sent.';
    final last = parts.removeLast();
    return '${parts.join(', ')} and $last waiting to be sent.';
  }

  static String _noun(QueuedOperationKind kind, int count) => switch (kind) {
    QueuedOperationKind.documentUpload => count == 1 ? 'file' : 'files',
    QueuedOperationKind.applicationSubmission =>
      count == 1 ? 'application' : 'applications',
    QueuedOperationKind.instructionResponse =>
      count == 1 ? 'reply to the office' : 'replies to the office',
    QueuedOperationKind.paymentProof =>
      count == 1 ? 'payment receipt' : 'payment receipts',
    QueuedOperationKind.contactVerificationRequest =>
      count == 1 ? 'verification request' : 'verification requests',
  };
}
