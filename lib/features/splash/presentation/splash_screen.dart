import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_typography.dart';

/// The first thing an applicant sees, and the only screen with no purpose but
/// to say whose app this is.
///
/// **Modelled on the Servana apps' splash**, at the owner's instruction, with
/// its composition rules carried over and its seven-petal choreography reduced
/// to the one mark this product has — the Municipality of Castilla's seal.
///
/// Four rules taken from `ServanaWorkerAPP/docs/SPLASH_MOTION_SPEC.md`, each
/// of which that app learned the hard way:
///
/// 1. **The animation never gates the destination, and the destination never
///    waits for the animation.** They run independently and whichever finishes
///    first is simply first. A warm start replaces the route mid-reveal; a
///    cold one settles the mark and then waits. Servana's Command 1 existed to
///    repair a splash that navigated on animation end while the router decided
///    the same thing from the session — two authorities for one decision.
/// 2. **Geometry is derived from the viewport**, never from a fixed design
///    canvas scaled to fit. A letterboxed canvas puts the mark in a different
///    place on a tablet than on a phone and shrinks it on short screens.
/// 3. **The status cue appears only after a delay, and never counts.** A
///    start that resolves in 300ms should show a clean brand moment, not a
///    spinner flickering on and off inside a third of a second. This screen
///    showed one unconditionally before today.
/// 4. **No haptics.** Startup is the most repeated interaction in the app, and
///    an animation ending is not an achievement.
///
/// Reduced motion is honoured by jumping to the assembled state, so the mark
/// is present and still rather than absent.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// The seal grows into place and fades in.
  late final Animation<double> _sealScale;
  late final Animation<double> _sealFade;

  /// The wordmark rises as it appears — a short lift, not a slide.
  late final Animation<double> _titleFade;
  late final Animation<double> _titleRise;

  late final Animation<double> _subtitleFade;

  /// Fades in last, and only if startup is still working by then.
  late final Animation<double> _statusFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.splashRevealDuration,
    );

    Animation<double> curve(double begin, double end, Curve c) =>
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: c),
        );

    _sealScale = Tween<double>(
      begin: 0.76,
      end: 1,
    ).animate(curve(0, 0.55, Curves.easeOutCubic));
    _sealFade = curve(0, 0.34, Curves.easeOut);
    _titleFade = curve(0.34, 0.66, Curves.easeOut);
    _titleRise = Tween<double>(
      begin: 14,
      end: 0,
    ).animate(curve(0.34, 0.66, Curves.easeOutCubic));
    _subtitleFade = curve(0.55, 0.82, Curves.easeOut);
    _statusFade = curve(0.78, 1, Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Read before starting, as Servana does: a reduced-motion user gets the
      // assembled mark immediately rather than no mark at all.
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // Nothing here waits for the animation, and the animation does not wait
    // for this. `authProvider` is the router's refreshListenable, so the
    // redirect fires the moment the session resolves — rule 1.
    await context.read<AuthProvider>().loadSession();
  }

  @override
  Widget build(BuildContext context) {
    // Rule 2: derived from the viewport. The seal takes a third of the
    // shorter side, bounded so it neither disappears on a small phone nor
    // dominates a tablet.
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final sealSize = (shortest * 0.34).clamp(96.0, 168.0);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: _sealFade.value,
                    child: Transform.scale(
                      scale: _sealScale.value,
                      child: Container(
                        width: sealSize,
                        height: sealSize,
                        padding: EdgeInsets.all(sealSize * 0.06),
                        decoration: const BoxDecoration(
                          color: AppColors.textOnPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/castilla-seal.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: _titleFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _titleRise.value),
                      child: Text(
                        AppStrings.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textOnPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: _subtitleFade.value,
                    child: Text(
                      AppStrings.splashSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textOnPrimaryMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  // Rule 3. Held at zero opacity for most of the reveal, so a
                  // start that resolves quickly never shows it at all.
                  Opacity(
                    opacity: _statusFade.value,
                    child: const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        color: AppColors.textOnPrimary,
                        strokeWidth: 2.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
