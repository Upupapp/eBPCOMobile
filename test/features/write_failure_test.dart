import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/models/money.dart';
import 'package:ebpco_user_app/core/models/application_lineage.dart';
import 'package:ebpco_user_app/core/models/application_model.dart';
import 'package:ebpco_user_app/core/models/business_model.dart';
import 'package:ebpco_user_app/core/models/document_model.dart';
import 'package:ebpco_user_app/core/models/notification_event.dart';
import 'package:ebpco_user_app/core/models/payment_assessment_model.dart';
import 'package:ebpco_user_app/core/providers/application_intent_provider.dart';
import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/business_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:ebpco_user_app/core/repositories/business_repository.dart';
import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';
import 'package:ebpco_user_app/core/theme/app_theme.dart';
import 'package:ebpco_user_app/features/applications/presentation/widgets/submit_permit_application.dart';
import 'package:ebpco_user_app/features/business/presentation/register_business_screen.dart';
import 'package:ebpco_user_app/shared/widgets/buttons/primary_button.dart';

/// Writes that fail.
///
/// U-07 covered the reads. A failing read shows the wrong thing; a failing
/// write loses work, and every write in the app was unguarded.
///
/// The submit path was the worst of them, and it was newly built: the throw
/// skipped the `pushReplacement` at every call site, so pressing Submit after
/// nine steps did nothing at all — no confirmation, no error, no way to tell
/// whether the application had been filed.

class _Offline implements Exception {}

class _ThrowingApplications implements ApplicationsRepository {
  @override
  Future<ApplicationModel> fetchDetail(String applicationId) async =>
      throw UnimplementedError();

  @override
  Future<List<ApplicationModel>> fetchAll() async => const [];
  @override
  Future<ApplicationModel> submitApplication({
    required String businessId,
    required String businessName,
    required ApplicationType type,
    required List<DocumentModel> documents,
    String? permitTypeLabel,
    String? applicationNumber,
    ApplicationLineage? lineage,
    List<String> documentIds = const [],
    String? location,
    Map<String, Object?>? form,
  }) async => throw _Offline();
  @override
  Future<ApplicationModel> attachPayment(
    String applicationId, {
    required PaymentMethod method,
    required String referenceNumber,
    required DateTime paidOn,
    PesoAmount? amountPaid,
    DocumentModel? proof,
    String? documentId,
  }) async => throw _Offline();
  @override
  Future<ApplicationModel> resubmitDocument(
    String applicationId, {
    required String documentId,
    required DocumentModel replacement,
  }) async => throw UnimplementedError();

  @override
  Future<ApplicationModel> advanceStatus(String id) async => throw _Offline();
}

class _ThrowingBusinesses implements BusinessRepository {
  @override
  Future<List<BusinessModel>> fetchAll() async => const [];
  @override
  Future<BusinessModel> registerBusiness({
    required String name,
    required BusinessCategory category,
    required String street,
    required String barangay,
    required String city,
    required String province,
  }) async => throw _Offline();
}

class _ThrowingNotifications implements NotificationsRepository {
  @override
  Future<List<NotificationEvent>> fetchAll() async => const [];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a failed submission says so instead of doing nothing', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Every wizard's submit handler reads this to pick up a pending
          // renewal or amendment.
          ChangeNotifierProvider<ApplicationIntentProvider>(
            create: (_) => ApplicationIntentProvider(),
          ),
          ChangeNotifierProvider<NotificationsProvider>(
            create: (_) =>
                NotificationsProvider(repository: _ThrowingNotifications()),
          ),
          ChangeNotifierProvider<ApplicationsProvider>(
            create: (context) => ApplicationsProvider(
              notifications: context.read<NotificationsProvider>(),
              repository: _ThrowingApplications(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              ctx = context;
              return const Scaffold();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final pending = submitPermitApplication(
      ctx,
      referenceNumber: 'FNC-2026-000001',
      permitTypeLabel: 'Fencing Permit',
      applicantName: 'Juan Dela Cruz',
    );
    await tester.pump(const Duration(seconds: 1));
    final result = await pending;
    await tester.pump();

    expect(
      result,
      isNull,
      reason: 'the caller must be able to tell it did not file',
    );
    expect(tester.takeException(), isNull, reason: 'and not by throwing');
    expect(find.textContaining('Could not submit'), findsOneWidget);
    expect(
      find.textContaining('nothing you entered has been lost'),
      findsOneWidget,
    );
  });

  testWidgets('a failed business registration releases the button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NotificationsProvider>(
            create: (_) =>
                NotificationsProvider(repository: _ThrowingNotifications()),
          ),
          ChangeNotifierProvider<BusinessProvider>(
            create: (context) => BusinessProvider(
              notifications: context.read<NotificationsProvider>(),
              repository: _ThrowingBusinesses(),
            ),
          ),
        ],
        child: const MaterialApp(home: RegisterBusinessScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Fill every field, and pick a category, so validation passes.
    final fields = find.byType(TextFormField);
    expect(fields, findsWidgets);
    for (var i = 0; i < fields.evaluate().length; i++) {
      await tester.enterText(fields.at(i), 'Test value');
    }
    await tester.pump();

    final dropdown = find.byType(DropdownButtonFormField<BusinessCategory>);
    if (dropdown.evaluate().isNotEmpty) {
      await tester.ensureVisible(dropdown.first);
      await tester.tap(dropdown.first);
      await tester.pumpAndSettle();
      final option = find.byType(DropdownMenuItem<BusinessCategory>).first;
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option, warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    }

    final submit = find.widgetWithText(PrimaryButton, 'Register Business');
    expect(submit, findsOneWidget, reason: 'the form must be submittable');

    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('Could not register the business'),
      findsOneWidget,
      reason: 'the applicant must be told, not left watching a spinner',
    );
    expect(
      tester.widget<PrimaryButton>(submit).isLoading,
      isFalse,
      reason: 'the button must be usable again so they can retry',
    );
  });
}
