import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SkillLinkApp());
    expect(find.byType(SkillLinkApp), findsOneWidget);

    // Elapse the splash screen's 2s navigation timer and let the route
    // transition to the onboarding screen complete, so no timers are left
    // pending when the test ends.
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
