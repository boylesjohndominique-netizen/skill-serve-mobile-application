import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/core/widgets/cards/review_card.dart';
import 'package:skillserve_mobile/features/reviews/models/review_model.dart';

final _review = ReviewModel(
  id: '7',
  bookingId: '12',
  clientName: 'Maria',
  rating: 2,
  comment: 'He never showed up.',
  createdAt: DateTime(2026, 10, 1),
);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));

void main() {
  testWidgets('a review can be reported from a labelled button or a long-press', (tester) async {
    var reports = 0;
    await tester.pumpWidget(_host(ReviewCard(review: _review, onReport: () => reports++)));
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Report'));
    await tester.longPress(find.text('He never showed up.'));
    expect(reports, 2);
  });

  testWidgets('no report action on your own review or for a guest', (tester) async {
    await tester.pumpWidget(_host(ReviewCard(review: _review)));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Report'), findsNothing);
  });
}
