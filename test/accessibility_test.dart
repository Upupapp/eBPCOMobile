import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/repositories/business_repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/constants/app_constants.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/lifecycle_status.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/models/permit_classification.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/business_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:ebpco_user_app/features/notifications/presentation/notifications_screen.dart';
import 'package:ebpco_user_app/features/profile/presentation/citizens_charter_screen.dart';

class _Applications implements ApplicationsRepository {
  _Applications(this.applications);
  final List<ApplicationModel> applications;

  @override
  Future<List<ApplicationModel>> fetchAll() async => applications;

  @override
  Future<ApplicationModel> submitApplication({
    required String businessId,
    required String businessName,
    required ApplicationType type,
    required List<DocumentModel> documents,
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    DocumentModel? proof,
  }) => throw UnimplementedError();

  @override
  Future<ApplicationModel> advanceStatus(String applicationId) =>
      throw UnimplementedError();
}

class _Notifications implements NotificationsRepository {
  _Notifications(this.events);
  final List<NotificationEvent> events;

  @override
  Future<List<NotificationEvent>> fetchAll() async => events;
}

final _now = DateTime(2026, 8, 18);

ApplicationModel _application({int openInstructionCount = 1}) =>
    ApplicationModel(
      id: 'app-1',
      applicationNumber: 'E-BPCO-2026-000145',
      businessId: 'biz-1',
      businessName: "Juan's General Merchandise",
      type: ApplicationType.newPermit,
      status: ApplicationStatus.underReview,
      submittedDate: DateTime(2026, 8, 12),
      lifecycleStatus: ApplicationLifecycleStatus.underEvaluation,
      classification: PermitClassification.highlyTechnical,
      permitTypeLabel: 'New Construction',
      openInstructionCount: openInstructionCount,
    );

Widget _app(Widget home, {double textScale = 1.0}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) => NotificationsProvider(
          repository: _Notifications([
            NotificationEvent(
              id: 'n1',
              type: NotificationType.letterOfInstructionIssued,
              applicationId: 'app-1',
              applicationNumber: 'E-BPCO-2026-000145',
              payload: const {'count': '2'},
              createdAt: _now,
            ),
          ]),
          clock: () => _now,
        ),
      ),
      ChangeNotifierProvider<BusinessProvider>(
        create: (context) => BusinessProvider(notifications: context.read<NotificationsProvider>(), repository: MockBusinessRepository()),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: _Applications([_application()]),
          clock: () => _now,
        ),
      ),
    ],
    child: MaterialApp(
      // The real app applies AppTheme, and the theme is where the 48dp
      // minimum on buttons lives. A bare MaterialApp here would test Material
      // defaults rather than this app.
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: home,
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

/// Every tappable target must meet the app's own 48dp minimum. Anything
/// smaller is hard to hit accurately on a phone held one-handed, which is how
/// most of this app's users will hold it.
///
/// IconButtons are measured at the button rather than at the ink: Material
/// draws them 40dp but expands the *hit* area to 48 via the default
/// `MaterialTapTargetSize.padded`, so measuring the InkWell inside one would
/// fail a control that is actually fine.
void _expectTouchTargets(WidgetTester tester) {
  const minimum = AppConstants.minTouchTarget;
  for (final button in find.byType(IconButton).evaluate()) {
    final size = tester.getSize(find.byWidget(button.widget));
    expect(
      size.height,
      greaterThanOrEqualTo(minimum - 0.5),
      reason: 'an IconButton hit area is only ${size.height}dp tall',
    );
  }

  for (final element in find.byType(InkWell).evaluate()) {
    var insideIconButton = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is IconButton) {
        insideIconButton = true;
        return false;
      }
      return true;
    });
    if (insideIconButton) continue;

    final size = tester.getSize(find.byWidget(element.widget));
    if (size.isEmpty) continue;

    // Name the enclosing widget, so a failure says which control is too small
    // rather than leaving the reader to hunt for it.
    final owners = <String>[];
    element.visitAncestorElements((ancestor) {
      final name = ancestor.widget.runtimeType.toString();
      if (name.startsWith('_') || name.startsWith('App') ||
          name.contains('Card') || name.contains('Tile') ||
          name.contains('Button') || name.contains('Header')) {
        owners.add(name);
      }
      return owners.length < 3;
    });

    expect(
      size.height,
      greaterThanOrEqualTo(minimum - 0.5),
      reason:
          'a tap target is only ${size.height}dp tall, inside '
          '${owners.join(" < ")}',
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('200% text scale', () {
    // The riskiest surfaces are the ones packing a status, a countdown, and a
    // reference into one row.
    testWidgets('Home survives without overflowing', (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(const DashboardScreen(), textScale: 2.0));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Letter of Instruction issued'), findsWidgets);
    });

    testWidgets('Notifications survives without overflowing', (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(const NotificationsScreen(), textScale: 2.0));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Needs your action (1)'), findsOneWidget);
    });

    testWidgets('the Citizen’s Charter survives without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          const CitizensCharterScreen(permitType: 'New Construction'),
          textScale: 2.0,
        ),
      );
      await _settle(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('touch targets', () {
    testWidgets('Home meets the 48dp minimum', (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(const DashboardScreen()));
      await _settle(tester);

      _expectTouchTargets(tester);
    });

    testWidgets('Notifications meets the 48dp minimum', (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(const NotificationsScreen()));
      await _settle(tester);

      _expectTouchTargets(tester);
    });
  });

  group('screen reader labels', () {
    testWidgets('an action card announces what is needed and for which application', (
      tester,
    ) async {
      // Disposed inline rather than in a tearDown: flutter_test verifies no
      // handle is outstanding *before* tearDowns run.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_app(const DashboardScreen()));
      await _settle(tester);

      // The card is one semantic node carrying the whole message, rather than
      // a scatter of unlabelled fragments a screen reader walks separately.
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Action required: Letter of Instruction issued.*'
            r'E-BPCO-2026-000145',
            dotAll: true,
          ),
        ),
        // A merged node and its parent can both carry the label; what matters
        // is that a screen reader reaches it at all.
        findsAtLeastNWidgets(1),
      );

      handle.dispose();
    });

    testWidgets('the pledge countdown is announced in words, not just colour', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_app(const DashboardScreen()));
      await _settle(tester);

      expect(
        find.bySemanticsLabel(RegExp('working day.* remaining')),
        findsAtLeastNWidgets(1),
      );

      handle.dispose();
    });
  });
}
