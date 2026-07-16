import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/widgets/primary_button.dart';
import '../features/applications/presentation/applications_placeholder_screen.dart';
import '../features/authentication/presentation/forgot_password_screen.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/register_screen.dart';
import '../features/authentication/presentation/registration_success_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/payments/presentation/payments_placeholder_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/shell/presentation/main_shell.dart';
import '../features/splash/presentation/splash_screen.dart';

/// Builds the application's [GoRouter] configuration. A single router
/// instance is created for the app's lifetime and driven by [authProvider]
/// via [GoRouter.refreshListenable], so session/onboarding changes trigger
/// redirect re-evaluation without rebuilding the router itself.
class AppRouter {
  AppRouter._();

  static const _authRoutes = {
    '/login',
    '/register',
    '/forgot-password',
    '/registration-success',
  };

  static GoRouter build(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) => _redirect(authProvider, state),
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/registration-success',
          builder: (context, state) => const RegistrationSuccessScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/app/home',
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/app/applications',
                  builder: (context, state) =>
                      const ApplicationsPlaceholderScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/app/payments',
                  builder: (context, state) =>
                      const PaymentsPlaceholderScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/app/notifications',
                  builder: (context, state) => const NotificationsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/app/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => const _NotFoundScreen(),
    );
  }

  static String? _redirect(AuthProvider authProvider, GoRouterState state) {
    final location = state.matchedLocation;
    final isSplash = location == '/splash';
    final isOnboarding = location == '/onboarding';
    final isAuthRoute = _authRoutes.contains(location);

    if (authProvider.status == AuthStatus.unknown) {
      return isSplash ? null : '/splash';
    }

    if (!authProvider.onboardingCompleted) {
      return isOnboarding ? null : '/onboarding';
    }

    if (!authProvider.isLoggedIn) {
      if (isAuthRoute) return null;
      return '/login';
    }

    if (isSplash || isOnboarding || isAuthRoute || location == '/app') {
      return '/app/home';
    }

    return null;
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_outlined,
                  size: 56,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Page not found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "The page you're looking for doesn't exist.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Back to Home',
                  onPressed: () => context.go('/app/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
