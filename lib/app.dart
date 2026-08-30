import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/providers/addition_extension_permit_provider.dart';
import 'core/providers/application_intent_provider.dart';
import 'core/providers/contact_verification_provider.dart';
import 'core/sync/sync_provider.dart';
import 'core/sync/offline_queue.dart';
import 'core/drafts/draft_persistence_barrel.dart';
import 'core/providers/applications_provider.dart';
import 'core/repositories/contact_verification_repository.dart';
import 'core/providers/architectural_permit_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/building_permit_provider.dart';
import 'core/providers/business_provider.dart';
import 'core/providers/certificate_of_occupancy_provider.dart';
import 'core/providers/civil_structural_permit_provider.dart';
import 'core/providers/demolition_permit_provider.dart';
import 'core/providers/documents_provider.dart';
import 'core/providers/electrical_permit_provider.dart';
import 'core/providers/electronics_permit_provider.dart';
import 'core/providers/excavation_permit_provider.dart';
import 'core/providers/fencing_permit_provider.dart';
import 'core/providers/interior_design_permit_provider.dart';
import 'core/providers/mechanical_permit_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'core/providers/notifications_provider.dart';
import 'core/providers/plumbing_permit_provider.dart';
import 'core/providers/renovation_permit_provider.dart';
import 'core/providers/sanitary_plumbing_permit_provider.dart';
import 'core/providers/professionals_provider.dart';
import 'core/repositories/repository_factory.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/sign_permit_provider.dart';
import 'core/providers/fsec_permit_provider.dart';
import 'core/providers/fsic_permit_provider.dart';
import 'core/providers/zoning_permit_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/text_scale_clamp.dart';
import 'routes/app_router.dart';

/// Root widget for the E-BPCO User App. Wires up global providers, the
/// Material 3 theme, and the go_router configuration.
class EbpcoApp extends StatefulWidget {
  const EbpcoApp({super.key});

  @override
  State<EbpcoApp> createState() => _EbpcoAppState();
}

class _EbpcoAppState extends State<EbpcoApp> with WidgetsBindingObserver {
  final AuthProvider _authProvider = AuthProvider();
  late final GoRouter _router = AppRouter.build(_authProvider);

  /// Owns the durable queue for the whole app. Built here rather than in a
  /// `create` callback because the lifecycle observer below has to reach it,
  /// and because two queues over one keychain key would each overwrite the
  /// other's saves.
  late final SyncProvider _sync = SyncProvider(
    queue: OfflineQueue(SecureQueueStore()),
    api: _repositories.client,
  );

  late final RepositoryFactory _repositories = RepositoryFactory();

  /// One store behind every persisted wizard draft.
  ///
  /// Built here, and the two providers that use it built here too, for the
  /// same two reasons the queue above is: `initState` has to reach them to
  /// start the restore before anything renders, and all drafts share a single
  /// keychain record, so two stores would each overwrite the other's writes.
  ///
  /// All nineteen wizards write here, each under its own key, and all of them
  /// share this one record — which is why `DraftPersistence` serialises its
  /// writes. See M-48.
  final DraftPersistence _drafts = DraftPersistence(SecureDraftStore());

  // All nineteen wizards, built here rather than in a `create` callback.
  // `initState` has to reach them to start the restore before anything
  // renders, and a lazily-built provider would not begin reading until
  // something asked for it — by which time the applicant may already be
  // looking at an empty Drafts list.
  late final BuildingPermitProvider _buildingPermit = BuildingPermitProvider(
    persistence: _drafts,
  );
  late final RenovationPermitProvider _renovation = RenovationPermitProvider(
    persistence: _drafts,
  );
  late final AdditionExtensionPermitProvider _additionExtension =
      AdditionExtensionPermitProvider(persistence: _drafts);
  late final DemolitionPermitProvider _demolition = DemolitionPermitProvider(
    persistence: _drafts,
  );
  late final ArchitecturalPermitProvider _architectural =
      ArchitecturalPermitProvider(persistence: _drafts);
  late final CivilStructuralPermitProvider _civilStructural =
      CivilStructuralPermitProvider(persistence: _drafts);
  late final ElectricalPermitProvider _electrical = ElectricalPermitProvider(
    persistence: _drafts,
  );
  late final MechanicalPermitProvider _mechanical = MechanicalPermitProvider(
    persistence: _drafts,
  );
  late final SanitaryPlumbingPermitProvider _sanitaryPlumbing =
      SanitaryPlumbingPermitProvider(persistence: _drafts);
  late final PlumbingPermitProvider _plumbing = PlumbingPermitProvider(
    persistence: _drafts,
  );
  late final ElectronicsPermitProvider _electronics = ElectronicsPermitProvider(
    persistence: _drafts,
  );
  late final InteriorDesignPermitProvider _interiorDesign =
      InteriorDesignPermitProvider(persistence: _drafts);
  late final FencingPermitProvider _fencingPermit = FencingPermitProvider(
    persistence: _drafts,
  );
  late final SignPermitProvider _sign = SignPermitProvider(
    persistence: _drafts,
  );
  late final ExcavationPermitProvider _excavation = ExcavationPermitProvider(
    persistence: _drafts,
  );
  late final CertificateOfOccupancyProvider _certificateOfOccupancy =
      CertificateOfOccupancyProvider(persistence: _drafts);
  late final ZoningPermitProvider _zoning = ZoningPermitProvider(
    persistence: _drafts,
  );
  late final FsicPermitProvider _fsic = FsicPermitProvider(
    persistence: _drafts,
  );
  late final FsecPermitProvider _fsec = FsecPermitProvider(
    persistence: _drafts,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Count what is waiting before anything renders, so a queued item is
    // visible from the first frame rather than after the first flush.
    _sync.refresh();
    // Read back anything the applicant was part-way through. Deliberately not
    // awaited: a keychain read must not delay the first frame, and each
    // provider refuses to overwrite a draft the applicant has already started
    // typing into while the read was in flight.
    _buildingPermit.restoreFromStore();
    _renovation.restoreFromStore();
    _additionExtension.restoreFromStore();
    _demolition.restoreFromStore();
    _architectural.restoreFromStore();
    _civilStructural.restoreFromStore();
    _electrical.restoreFromStore();
    _mechanical.restoreFromStore();
    _sanitaryPlumbing.restoreFromStore();
    _plumbing.restoreFromStore();
    _electronics.restoreFromStore();
    _interiorDesign.restoreFromStore();
    _fencingPermit.restoreFromStore();
    _sign.restoreFromStore();
    _excavation.restoreFromStore();
    _certificateOfOccupancy.restoreFromStore();
    _zoning.restoreFromStore();
    _fsic.restoreFromStore();
    _fsec.restoreFromStore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repositories.dispose();
    super.dispose();
  }

  /// Resuming is the one connectivity signal available without a package.
  ///
  /// It is not a good one — an applicant can resume the app still offline, and
  /// can regain a connection without ever backgrounding it — but it costs
  /// nothing and covers the common case of walking back into signal and
  /// reopening the app. A real connectivity trigger needs `connectivity_plus`,
  /// which is the owner's call; see `SyncProvider`'s `ConnectivityMonitor`.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<NavigationProvider>(
          create: (_) => NavigationProvider(),
        ),
        // First, because the repositories every other provider is built from
        // come out of it. One place decides whether this build talks to the
        // API or to seed data, so a build cannot end up half-live.
        Provider<RepositoryFactory>.value(value: _repositories),
        // The offline queue, finally constructed. Everything queued by a write
        // that failed lives here until it reaches the LGU.
        ChangeNotifierProvider<SyncProvider>.value(value: _sync),
        // Declared before ApplicationsProvider/BusinessProvider so their
        // `create` callbacks can read it via `context.read` to post
        // notifications for submit/pay/advance/register actions.
        ChangeNotifierProvider<NotificationsProvider>(
          create: (context) => NotificationsProvider(
            repository: context.read<RepositoryFactory>().notifications(),
          ),
        ),
        ChangeNotifierProvider<BusinessProvider>(
          create: (context) => BusinessProvider(
            notifications: context.read<NotificationsProvider>(),
            repository: context.read<RepositoryFactory>().businesses(),
          ),
        ),
        ChangeNotifierProvider<ApplicationsProvider>(
          create: (context) => ApplicationsProvider(
            notifications: context.read<NotificationsProvider>(),
            repository: context.read<RepositoryFactory>().applications(),
            // The other half of the write path: files go to /documents before
            // an application references them. Refuses on a mock build rather
            // than fabricating ids. M-47.
            documentUploads: context
                .read<RepositoryFactory>()
                .documentUploads(),
          ),
        ),
        // Per-channel contact verification. Seeded from the session and kept
        // in step with it: a changed address is an unverified address, and
        // carrying a verified status across an edit would let someone confirm
        // one mailbox and substitute another.
        ChangeNotifierProxyProvider<AuthProvider, ContactVerificationProvider>(
          create: (_) => ContactVerificationProvider(
            repository: MockContactVerificationRepository(),
            // TAB 11 built the enqueue-on-failure path and could only be
            // handed null, because nothing constructed a queue. Its acceptance
            // criterion — "verification requests survive a failed network
            // call" — was true of the unit and false of the product until
            // this line.
            queue: _sync.queue,
          ),
          update: (_, auth, verification) {
            final provider =
                verification ??
                ContactVerificationProvider(
                  repository: MockContactVerificationRepository(),
                  queue: _sync.queue,
                );
            provider.updateContactDetails(
              email: auth.currentUser?.email,
              mobileNumber: auth.currentUser?.mobileNumber,
            );
            return provider;
          },
        ),

        // Holds a pending renewal or amendment between the screen that starts
        // it and the wizard that files it.
        ChangeNotifierProvider<ApplicationIntentProvider>(
          create: (_) => ApplicationIntentProvider(),
        ),
        ChangeNotifierProvider<DocumentsProvider>(
          create: (_) => DocumentsProvider(),
        ),
        ChangeNotifierProvider<BuildingPermitProvider>.value(
          value: _buildingPermit,
        ),
        ChangeNotifierProvider<RenovationPermitProvider>.value(
          value: _renovation,
        ),
        ChangeNotifierProvider<AdditionExtensionPermitProvider>.value(
          value: _additionExtension,
        ),
        ChangeNotifierProvider<DemolitionPermitProvider>.value(
          value: _demolition,
        ),
        ChangeNotifierProvider<ArchitecturalPermitProvider>.value(
          value: _architectural,
        ),
        ChangeNotifierProvider<CivilStructuralPermitProvider>.value(
          value: _civilStructural,
        ),
        ChangeNotifierProvider<ElectricalPermitProvider>.value(
          value: _electrical,
        ),
        ChangeNotifierProvider<ElectronicsPermitProvider>.value(
          value: _electronics,
        ),
        ChangeNotifierProvider<InteriorDesignPermitProvider>.value(
          value: _interiorDesign,
        ),
        ChangeNotifierProvider<FencingPermitProvider>.value(
          value: _fencingPermit,
        ),
        ChangeNotifierProvider<MechanicalPermitProvider>.value(
          value: _mechanical,
        ),
        ChangeNotifierProvider<SanitaryPlumbingPermitProvider>.value(
          value: _sanitaryPlumbing,
        ),
        ChangeNotifierProvider<PlumbingPermitProvider>.value(value: _plumbing),
        ChangeNotifierProvider<SignPermitProvider>.value(value: _sign),
        ChangeNotifierProvider<ExcavationPermitProvider>.value(
          value: _excavation,
        ),
        ChangeNotifierProvider<CertificateOfOccupancyProvider>.value(
          value: _certificateOfOccupancy,
        ),
        ChangeNotifierProvider<ZoningPermitProvider>.value(value: _zoning),
        ChangeNotifierProvider<FsicPermitProvider>.value(value: _fsic),
        ChangeNotifierProvider<FsecPermitProvider>.value(value: _fsec),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<ProfessionalsProvider>(
          create: (context) => ProfessionalsProvider(
            notifications: context.read<NotificationsProvider>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        // The scale ceiling, and why it is where it is, live in
        // TextScaleClamp — next to the constant rather than in a comment on
        // the widget that happens to apply it.
        builder: (context, child) => TextScaleClamp(child: child!),
      ),
    );
  }
}
