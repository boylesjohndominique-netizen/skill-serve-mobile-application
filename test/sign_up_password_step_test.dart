import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skillserve_mobile/core/theme/app_theme.dart';
import 'package:skillserve_mobile/features/auth/controllers/auth_controller.dart';
import 'package:skillserve_mobile/features/identity/controllers/identity_controller.dart';
import 'package:skillserve_mobile/routes/app_router.dart';

import 'support/scanned_identity.dart';

/// Sign-up asks for the password after the emailed code, and Forgot
/// password runs on a code too.
Widget _app(String route) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
      ChangeNotifierProvider<IdentityController>(create: (_) => scannedIdentity()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: GoRouter(initialLocation: route, routes: appRoutes),
      ),
    ),
  );
}

void main() {
  testWidgets('the sign-up form asks for no password; the code comes first',
      (tester) async {
    await tester.pumpWidget(_app('/register'));
    await tester.pumpAndSettle();

    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsNothing);
    expect(find.text('Confirm password'), findsNothing);
    expect(find.textContaining('6-digit code'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('the password step needs a matching confirmation', (tester) async {
    await tester.pumpWidget(_app('/create-password'));
    await tester.pumpAndSettle();

    expect(find.text('Create your password'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'chosenpass123');
    await tester.enterText(find.byType(TextFormField).at(1), 'different123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('the password step refuses a short password', (tester) async {
    await tester.pumpWidget(_app('/create-password'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'short');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('forgot password sends a code to the prefilled address',
      (tester) async {
    await tester.pumpWidget(_app('/forgot-password?email=juan%40gmail.com'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('juan@gmail.com'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
    expect(find.textContaining('reset link'), findsNothing);
  });
}
