import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../models/onboarding_item.dart';

/// Renders a single onboarding page's icon, title, and description.
class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    color: AppColors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: 72,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
