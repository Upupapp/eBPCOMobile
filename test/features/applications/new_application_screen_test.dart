import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/repositories/business_repository.dart';

import 'package:ebpco_user_app/core/repositories/notifications_repository.dart';

import 'package:ebpco_user_app/core/repositories/applications_repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/providers/applications_provider.dart';
import 'package:ebpco_user_app/core/providers/business_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/features/applications/presentation/new_application_screen.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/widgets/mock_upload.dart';
import 'package:ebpco_user_app/features/documents/presentation/widgets/attach_document_sheet.dart';

Widget _wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NotificationsProvider>(
        create: (_) =>
            NotificationsProvider(repository: MockNotificationsRepository()),
      ),
      ChangeNotifierProvider<BusinessProvider>(
        create: (context) => BusinessProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: MockBusinessRepository(),
        ),
      ),
      ChangeNotifierProvider<ApplicationsProvider>(
        create: (context) => ApplicationsProvider(
          notifications: context.read<NotificationsProvider>(),
          repository: MockApplicationsRepository(),
        ),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  // These wizards now attach documents through the real chooser sheet, which
  // reaches for the camera, gallery, and system file picker — none of them
  // available under `flutter test`. Swap it for a stub that returns a
  // fabricated document so the upload slots behave the way the steps'
  // validation expects.
  setUp(() {
    debugAttachDocumentOverride = (context, {required label}) async =>
        createMockDocument(label);
  });

  tearDown(() => debugAttachDocumentOverride = null);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'lets the user pick a business/type and reach the document checklist',
    (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const NewApplicationScreen()));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Business').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Juan's General Merchandise").last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Application type').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Business Permit').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle(const Duration(milliseconds: 350));

      expect(tester.takeException(), isNull);
      expect(find.text('Valid Government ID'), findsOneWidget);
      expect(find.text('Barangay Clearance'), findsOneWidget);
      expect(find.text('Proof of Business Address'), findsOneWidget);
    },
  );
}
