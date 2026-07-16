import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/dashboard_provider.dart';
import '../core/providers/navigation_provider.dart';
import '../core/providers/notifications_provider.dart';
import 'app_router.dart';
import 'app_theme.dart';

/// Root widget for the E-BPCO User App. Wires up global providers, the
/// Material 3 theme, and the go_router configuration.
class EbpcoApp extends StatefulWidget {
  const EbpcoApp({super.key});

  @override
  State<EbpcoApp> createState() => _EbpcoAppState();
}

class _EbpcoAppState extends State<EbpcoApp> {
  final AuthProvider _authProvider = AuthProvider();
  late final GoRouter _router = AppRouter.build(_authProvider);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<NavigationProvider>(
          create: (_) => NavigationProvider(),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(),
        ),
        ChangeNotifierProvider<NotificationsProvider>(
          create: (_) => NotificationsProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
