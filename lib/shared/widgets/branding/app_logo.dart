import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_shadows.dart';

/// Reusable E-BPCO logo mark + app name, used across the splash, onboarding
/// and authentication screens.
///
/// **The mark is the Municipality of Castilla's own seal.** It used to be the
/// DILG seal — the Department of the Interior and Local Government. Changed 31
/// August 2026 at the owner's instruction: the app is the Municipality of
/// Castilla's, and the mark it signs itself with should be Castilla's.
///
/// **Corrected the same day.** The first version of this comment called the
/// DILG seal a misattribution — "claims an issuer it does not have". That was
/// too strong, and I did not know it: **the LGU is a partner with the DILG**,
/// which also co-issues the DILG–DPWH–DICT–DTI Joint Memorandum Circular the
/// Terms cite. The seal was not a fabrication. It was simply the wrong mark
/// for a screen where the app identifies itself, which is a different and
/// smaller thing to have got wrong.
///
/// The file is the LGU's own, copied byte-for-byte from
/// `eBPCO-Website/castilla-lgu-portal/public/assets/logos/castilla-seal.png`
/// — the seal the municipality publishes on its own site — rather than
/// re-encoded from a screenshot. It carries a transparent background, so it
/// sits on the white circle below without a visible edge.
class AppLogo extends StatelessWidget {
  final double iconSize;
  final double titleSize;
  final bool showSubtitle;
  final Color? iconBackgroundColor;

  /// Unused now that the mark is a fixed-colour official seal image; kept
  /// only so existing call sites don't need to change.
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
          padding: EdgeInsets.all(iconSize * 0.06),
          decoration: BoxDecoration(
            color: iconBackgroundColor ?? AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: AppShadows.card,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/castilla-seal.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: titleColor ?? AppColors.primary,
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
