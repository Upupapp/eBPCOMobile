import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// "As of {timestamp}" — shown whenever a surface is serving cached data.
///
/// Non-blocking by design. Losing the action stack because a refresh timed out
/// would hide exactly what the applicant opened the app for, so stale data
/// stays on screen and is labelled rather than withheld.
class StaleDataBanner extends StatelessWidget {
  final DateTime? lastLoadedAt;
  final VoidCallback? onRetry;

  const StaleDataBanner({super.key, required this.lastLoadedAt, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final at = lastLoadedAt;
    final stamp = at == null
        ? 'Not yet loaded'
        : 'As of ${DateFormat('MMM d, h:mm a').format(at)}';

    return Semantics(
      label: '$stamp. Showing saved data because the last refresh failed.',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '$stamp · showing saved data',
                style: AppTypography.helper,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, AppConstants.minTouchTarget),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
