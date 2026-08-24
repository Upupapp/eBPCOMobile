import 'package:flutter/material.dart';

/// Bounds the system text-scale factor for everything below it.
///
/// The app used to cap this at 1.3x. The reason was honest and is worth
/// keeping in view: layouts were built and checked against a 1.0x desktop
/// preview, and a real Android phone with Settings → Display → Font size
/// raised produced overflow and clipping that never appeared in development.
/// Capping the scale made the symptom go away.
///
/// It also capped accessibility. Someone who sets their phone to 200% because
/// they need 200% got 130%, on every screen, permanently.
///
/// The cap is now [maxScale], because the layouts underneath it were fixed
/// rather than worked around: all sixteen wizards, all sixteen shared widgets
/// and every one of the app's screens render clean at 2.0x, and the bottom
/// navigation bar — the first thing the old comment named — grows with the
/// scale instead of clipping its labels.
///
/// [maxScale] is deliberately the same number the accessibility suites assert
/// at. The app should not promise a scale nothing has rendered at, and it
/// should not withhold one that everything has. If those suites are extended
/// past 2.0, this moves with them.
///
/// [minScale] exists for the opposite reason: a user who shrinks system text
/// can otherwise reach sizes where labels are unreadable and touch targets
/// lose their text entirely.
class TextScaleClamp extends StatelessWidget {
  static const double minScale = 0.9;
  static const double maxScale = 2.0;

  final Widget child;

  const TextScaleClamp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: minScale, maxScaleFactor: maxScale);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: child,
    );
  }
}
