import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SkillLinkApp());
    expect(find.byType(SkillLinkApp), findsOneWidget);
  });
}
