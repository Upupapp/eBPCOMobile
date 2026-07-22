import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/core/providers/building_permit_provider.dart';
import 'package:ebpco_user_app/core/providers/notifications_provider.dart';
import 'package:ebpco_user_app/features/applications/presentation/building_permit/building_permit_wizard_screen.dart';

Future<void> _fill(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  expect(field, findsOneWidget, reason: 'field "$label" should exist');
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _selectDropdown(WidgetTester tester, String label, String option) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _pickDate(WidgetTester tester, int index) async {
  final dateFields = find.text('Select a date');
  await tester.tap(dateFields.at(index));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('navigating from step 1 through step 6 does not crash', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NotificationsProvider>(
            create: (_) => NotificationsProvider(),
          ),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<BuildingPermitProvider>(
            create: (context) => BuildingPermitProvider(
              notifications: context.read<NotificationsProvider>(),
            ),
          ),
        ],
        child: const MaterialApp(home: BuildingPermitWizardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'initial mount (step 1)');
    expect(find.text('Applicant Information'), findsOneWidget);

    // --- Step 1: Applicant Information ---
    await _fill(tester, 'Last Name', 'Dela Cruz');
    await _fill(tester, 'First Name', 'Juan');
    await _fill(tester, 'Telephone or Mobile Number', '09171234567');
    await _selectDropdown(tester, 'Form of Ownership', 'Individual / Sole Owner');
    await _fill(tester, 'Street', 'Rizal St.');
    await _fill(tester, 'Barangay', 'San Isidro');
    await _fill(tester, 'City or Municipality', 'Quezon City');
    await _fill(tester, 'Province', 'Metro Manila');
    await _fill(tester, 'ZIP Code', '1100');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'), warnIfMissed: false);
    await tester.pumpAndSettle();
    print('after step 1 -> exception: ${tester.takeException()}');
    expect(find.text('Property Location'), findsOneWidget, reason: 'should reach step 2');

    // --- Step 2: Property Location ---
    await _fill(tester, 'Lot Number', '12');
    await _fill(tester, 'TCT or OCT Number', 'TCT-1');
    await _fill(tester, 'Tax Declaration Number', 'TD-1');
    await _fill(tester, 'Street', 'Rizal St.');
    await _fill(tester, 'Barangay', 'San Isidro');
    await _fill(tester, 'City or Municipality', 'Quezon City');
    await _fill(tester, 'Province', 'Metro Manila');
    await _fill(tester, 'ZIP Code', '1100');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'), warnIfMissed: false);
    await tester.pumpAndSettle();
    print('after step 2 -> exception: ${tester.takeException()}');
    expect(find.text('Scope of Work'), findsOneWidget, reason: 'should reach step 3');

    // --- Step 3: Scope of Work ---
    await tester.tap(find.text('New Construction').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'), warnIfMissed: false);
    await tester.pumpAndSettle();
    print('after step 3 -> exception: ${tester.takeException()}');
    expect(find.text('Building Use'), findsOneWidget, reason: 'should reach step 4');

    // --- Step 4: Building Use ---
    await tester.tap(find.textContaining('Group A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'), warnIfMissed: false);
    await tester.pumpAndSettle();
    print('after step 4 -> exception: ${tester.takeException()}');
    expect(find.text('Project Details'), findsOneWidget, reason: 'should reach step 5');

    // --- Step 5: Project Details ---
    await _fill(tester, 'Total Floor Area', '120');
    await _fill(tester, 'Lot Area', '150');
    await _fill(tester, 'Total Estimated Construction Cost', '500000');
    await _pickDate(tester, 0);
    await _pickDate(tester, 0); // second remaining "Select a date" after first is filled
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'), warnIfMissed: false);
    await tester.pumpAndSettle();
    final exceptionAtStep6 = tester.takeException();
    print('after step 5 (entering step 6) -> exception: $exceptionAtStep6');
    if (exceptionAtStep6 != null) {
      print('STACK: ${exceptionAtStep6.toString()}');
    }
    expect(exceptionAtStep6, isNull, reason: 'transitioning into step 6 should not crash');
    expect(find.text('Architect or Civil Engineer'), findsOneWidget, reason: 'should reach step 6');
  });
}
