import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

import '../../../core/theme/app_typography.dart';

/// Consistent section title used across dashboard and list screens,
/// with an optional trailing action such as "See All".
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.sectionTitle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              // 48dp, not the 36 this used to force. A "See All" link is a
              // real target on a phone, and undersizing it to tighten the
              // header trades an accessibility floor for a few pixels.
              minimumSize: const Size(0, AppConstants.minTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
