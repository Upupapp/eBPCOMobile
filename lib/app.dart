import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/providers/addition_extension_permit_provider.dart';
import 'core/providers/applications_provider.dart';
import 'core/providers/architectural_permit_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/building_permit_provider.dart';
import 'core/providers/business_provider.dart';
import 'core/providers/civil_structural_permit_provider.dart';
import 'core/providers/demolition_permit_provider.dart';
import 'core/providers/electrical_permit_provider.dart';
import 'core/providers/mechanical_permit_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'core/providers/notifications_provider.dart';
import 'core/providers/plumbing_permit_provider.dart';
import 'core/providers/renovation_permit_provider.dart';
import 'core/providers/sanitary_plumbing_permit_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

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
        // Declared before ApplicationsProvider/BusinessProvider so their
        // `create` callbacks can read it via `context.read` to post
        // notifications for submit/pay/advance/register actions.
        ChangeNotifierProvider<NotificationsProvider>(
          create: (_) => NotificationsProvider(),
        ),
        ChangeNotifierProvider<BusinessProvider>(
          create: (context) => BusinessProvider(
            notifications: context.read<NotificationsProvider>(),
          ),
        ),
        ChangeNotifierProvider<ApplicationsProvider>(
          create: (context) => ApplicationsProvider(
            notifications: context.read<NotificationsProvider>(),
          ),
        ),
        ChangeNotifierProvider<BuildingPermitProvider>(
          create: (_) => BuildingPermitProvider(),
        ),
        ChangeNotifierProvider<RenovationPermitProvider>(
          create: (_) => RenovationPermitProvider(),
        ),
        ChangeNotifierProvider<AdditionExtensionPermitProvider>(
          create: (_) => AdditionExtensionPermitProvider(),
        ),
        ChangeNotifierProvider<DemolitionPermitProvider>(
          create: (_) => DemolitionPermitProvider(),
        ),
        ChangeNotifierProvider<ArchitecturalPermitProvider>(
          create: (_) => ArchitecturalPermitProvider(),
        ),
        ChangeNotifierProvider<CivilStructuralPermitProvider>(
          create: (_) => CivilStructuralPermitProvider(),
        ),
        ChangeNotifierProvider<ElectricalPermitProvider>(
          create: (_) => ElectricalPermitProvider(),
        ),
        ChangeNotifierProvider<MechanicalPermitProvider>(
          create: (_) => MechanicalPermitProvider(),
        ),
        ChangeNotifierProvider<SanitaryPlumbingPermitProvider>(
          create: (_) => SanitaryPlumbingPermitProvider(),
        ),
        ChangeNotifierProvider<PlumbingPermitProvider>(
          create: (_) => PlumbingPermitProvider(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
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
