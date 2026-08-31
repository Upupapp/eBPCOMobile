import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ebpco_user_app/core/providers/auth_provider.dart';
import 'package:ebpco_user_app/features/authentication/presentation/login_screen.dart';

Widget _wrapWithProviders(Widget child) {
  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => AuthProvider(),
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the email field, password field, and login action', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapWithProviders(const LoginScreen()));

    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    // The credential banner is debug-only since 31 August 2026 — it printed
    // a working account on the sign-in screen of every build. Tests run in
    // debug, so it is present here, and its wording changed with its scope.
    expect(find.textContaining('Debug build'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting an empty form', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapWithProviders(const LoginScreen()));

    await tester.tap(find.text('Log In'));
    await tester.pump();

    expect(find.text('Please enter your email address.'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const LoginScreen()));

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
