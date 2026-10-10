import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillserve_mobile/features/auth/views/widgets/otp_code_field.dart';

void main() {
  Future<(TextEditingController, List<String>)> pumpField(WidgetTester tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final completed = <String>[];
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: OtpCodeField(controller: controller, focusNode: focusNode, onCompleted: completed.add),
        ),
      ),
    ));
    await tester.pump();
    return (controller, completed);
  }

  testWidgets('the keyboard opens on its own when the code screen appears', (tester) async {
    await pumpField(tester);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('one tap on the boxes brings the keyboard back after it was closed', (tester) async {
    await pumpField(tester);
    // The user closes the keyboard; the field keeps its focus.
    tester.testTextInput.hide();
    expect(tester.testTextInput.isVisible, isFalse);

    // On a box, not between two: the boxes are what the user sees and taps.
    await tester.tapAt(tester.getTopLeft(find.byType(OtpCodeField)) + const Offset(22, 27));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('typed digits fill the boxes and the sixth one submits', (tester) async {
    final (controller, completed) = await pumpField(tester);

    await tester.enterText(find.byType(TextField), '12a3456');
    await tester.pump();

    expect(controller.text, '123456', reason: 'digits only');
    expect(completed, ['123456']);
    expect(find.text('6'), findsOneWidget);
  });
}
