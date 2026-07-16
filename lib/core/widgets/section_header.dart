import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

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
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
