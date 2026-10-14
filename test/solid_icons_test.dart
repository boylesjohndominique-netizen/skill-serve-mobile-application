import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:skillserve_mobile/core/constants/app_icons.dart';
import 'package:skillserve_mobile/core/widgets/misc/app_icon.dart';

void main() {
  testWidgets('a favourite is a full heart and a rating a full star; empty ones stay outlined', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Row(children: [
        AppIcon(AppIcons.favorite_rounded),
        AppIcon(AppIcons.star_rounded),
        AppIcon(AppIcons.favorite_border_rounded),
        AppIcon(AppIcons.star_outline_rounded),
      ]),
    ));

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    // The outline versions are still HugeIcons glyphs.
    expect(find.byType(HugeIcon), findsNWidgets(2));
  });
}
