import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skilllink_mobile/core/theme/app_theme.dart';
import 'package:skilllink_mobile/features/auth/controllers/auth_controller.dart';
import 'package:skilllink_mobile/routes/app_router.dart';

/// While a request is in flight the auth forms must be read-only: the value
/// being submitted cannot change underneath the request.
Widget _app(AuthController auth, String route) {
  return ChangeNotifierProvider<AuthController>.value(
    value: auth,
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

/// The busy state shows an indefinite spinner, so the tree never settles —
/// advance past the entrance animations with timed pumps instead.
Future<void> _settleAnimations(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Iterable<bool> _fieldEnabledStates(WidgetTester tester) => tester
    .widgetList<TextFormField>(find.byType(TextFormField))
    .map((f) => f.enabled);

void main() {
  for (final route in ['/login', '/register']) {
    testWidgets('$route fields accept input when idle', (tester) async {
      await tester.pumpWidget(_app(AuthController(), route));
      await _settleAnimations(tester);

      final states = _fieldEnabledStates(tester);
      expect(states, isNotEmpty);
      expect(states.every((enabled) => enabled), isTrue);
    });

    testWidgets('$route fields lock while a request is in flight',
        (tester) async {
      final auth = AuthController()..status = AuthStatus.authenticating;
      await tester.pumpWidget(_app(auth, route));
      await _settleAnimations(tester);

      final states = _fieldEnabledStates(tester);
      expect(states, isNotEmpty);
      expect(states.any((enabled) => enabled), isFalse,
          reason: 'every field on $route must be read-only while loading');
    });
  }

  testWidgets('a locked login form ignores typing', (tester) async {
    final auth = AuthController()..status = AuthStatus.authenticating;
    await tester.pumpWidget(_app(auth, '/login'));
    await _settleAnimations(tester);

    final email = find.byType(TextFormField).first;
    await tester.enterText(email, 'typed@example.com');
    await tester.pump();

    expect(find.text('typed@example.com'), findsNothing);
  });
}
