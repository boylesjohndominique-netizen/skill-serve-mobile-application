import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skillserve_mobile/core/theme/app_theme.dart';
import 'package:skillserve_mobile/features/auth/controllers/auth_controller.dart';
import 'package:skillserve_mobile/features/auth/models/auth_results.dart';
import 'package:skillserve_mobile/features/identity/controllers/identity_controller.dart';
import 'package:skillserve_mobile/routes/app_router.dart';

import 'support/scanned_identity.dart';

/// The screen a brand-new Google account lands on. The account is created
/// only when this form is submitted, so the tests cover what it collects
/// and what it does when there is nothing to finish.
Widget _app(AuthController auth, {String route = '/google-register', IdentityController? identity}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider<IdentityController>.value(value: identity ?? scannedIdentity()),
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

AuthController _authWithDraft() {
  return AuthController()
    ..googleDraft = const GoogleProfileDraft(
      idToken: 'token',
      email: 'juan@gmail.com',
      firstName: 'Maria',
      lastName: 'Santos',
    );
}

void main() {
  testWidgets('fills the form from the National ID, not the Google profile',
      (tester) async {
    await tester.pumpWidget(_app(_authWithDraft(), identity: scannedIdentity(givenNames: 'Juana', lastName: 'Reyes')));
    await tester.pumpAndSettle();

    expect(find.text('Finish signing up'), findsOneWidget);
    expect(find.text('juan@gmail.com'), findsOneWidget);
    // The ID is what gets reviewed, so its name wins over Google's "Maria".
    expect(find.text('Juana'), findsOneWidget);
    expect(find.text('Reyes'), findsOneWidget);
    expect(find.text('Maria'), findsNothing);
    expect(find.text('9876-5432-1098-7654'), findsOneWidget);
  });

  testWidgets('without a scan the National ID comes first', (tester) async {
    await tester.pumpWidget(_app(_authWithDraft(), identity: IdentityController()));
    await tester.pumpAndSettle();

    expect(find.text('Front of your National ID'), findsOneWidget);
    expect(find.text('Scan the front'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('asks providers for their professional details', (tester) async {
    await tester.pumpWidget(_app(_authWithDraft()));
    await tester.pumpAndSettle();

    // Customers are not asked for a specialization...
    expect(find.text('Specialization'), findsNothing);

    await tester.tap(find.text('I offer a service'));
    await tester.pumpAndSettle();

    // ...providers are, because the API requires one for their profile.
    expect(find.text('Specialization'), findsOneWidget);
    expect(find.text('Business name (optional)'), findsOneWidget);
  });

  testWidgets('a provider sign-up will not submit without a specialization',
      (tester) async {
    final auth = _authWithDraft();
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I offer a service'));
    await tester.pumpAndSettle();

    final submit = find.text('Continue');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Specialization is required'), findsOneWidget);
    // Nothing was sent, so the draft is still waiting to be completed.
    expect(auth.googleDraft, isNotNull);
  });

  testWidgets('without a draft there is nothing to finish', (tester) async {
    await tester.pumpWidget(_app(AuthController()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Google sign-in expired'), findsOneWidget);
    expect(find.text('Back to log in'), findsOneWidget);
  });

  testWidgets('backing out drops the draft, cancelling the sign-up',
      (tester) async {
    final auth = _authWithDraft();
    await tester.pumpWidget(_app(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cancel sign-up'));
    await tester.pumpAndSettle();

    expect(auth.googleDraft, isNull);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
