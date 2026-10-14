import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/reports/views/raise_dispute_sheet.dart';

void main() {
  testWidgets('a too-short reason says how many characters are needed', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => showRaiseDisputeSheet(context), child: const Text('open')),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Nothing typed yet: no message.
    expect(find.textContaining('Please write at least'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Leaks');
    await tester.pump();
    expect(find.text('Please write at least 10 characters (5/10).'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'The unit still leaks.');
    await tester.pump();
    expect(find.textContaining('Please write at least'), findsNothing);
  });
}
