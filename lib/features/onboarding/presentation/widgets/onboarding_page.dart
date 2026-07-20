import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/avatars/app_avatar.dart';
import '../../../../shared/widgets/layout/form_scroll_scaffold.dart';
import '../../models/onboarding_item.dart';

/// Renders a single onboarding page's icon, title, and description.
class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return FormScrollScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppAvatar(
            size: 160,
            icon: item.icon,
            iconSize: 72,
            backgroundColor: AppColors.lightBlue,
            foregroundColor: AppColors.primary,
          ),
          const SizedBox(height: 36),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: AppTypography.pageTitle,
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
