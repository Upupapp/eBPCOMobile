import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/upload_progress.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// What a citizen sees while their attachments are going to the office.
///
/// **A twenty-megabyte plan set used to show a spinner and nothing else**, for
/// as long as it took. On rural data that is minutes of a screen that gives no
/// sign the app is alive, and the reasonable thing for someone to do with it
/// is close the app — which loses the filing.
///
/// So it says three things a spinner cannot: how many documents there are,
/// which one is going now **by its own name**, and roughly how far through the
/// whole filing is.
///
/// The bar spans the SUBMISSION, not the file. A per-file bar that resets to
/// zero twenty-four times reads as no progress at all.
class UploadProgressSheet extends StatelessWidget {
  final UploadProgress progress;

  const UploadProgressSheet({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sending your application', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            // Named, not numbered. Someone watching an upload stall wants to
            // know which of their files it is.
            '${progress.position} — ${progress.label}',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 8,
              backgroundColor: AppColors.primaryLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            // Said plainly, because the alternative is a citizen closing the
            // app during the slowest part of the process.
            'Keep this screen open until it finishes. Your documents are '
            'being sent one at a time so the upload survives a slow '
            'connection.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
