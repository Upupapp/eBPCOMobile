import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Reusable text-based E-BPCO logo used across splash, onboarding, and
/// authentication screens. No external image assets are required.
class AppLogo extends StatelessWidget {
  final double iconSize;
  final double titleSize;
  final bool showSubtitle;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final Color? titleColor;

  const AppLogo({
    super.key,
    this.iconSize = 64,
    this.titleSize = 28,
    this.showSubtitle = true,
    this.iconBackgroundColor,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: iconBackgroundColor ?? AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(iconSize * 0.28),
          ),
          child: Icon(
            Icons.account_balance,
            size: iconSize * 0.55,
            color: iconColor ?? Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: titleColor ?? AppColors.primaryNavy,
            letterSpacing: 0.5,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            AppStrings.appTagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
