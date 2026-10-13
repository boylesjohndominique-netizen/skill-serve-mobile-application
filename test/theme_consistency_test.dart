import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/core/constants/app_colors.dart';
import 'package:skillserve_mobile/core/constants/app_icons.dart';
import 'package:skillserve_mobile/core/theme/app_theme.dart';
import 'package:skillserve_mobile/core/widgets/feedback/app_notice.dart';
import 'package:skillserve_mobile/features/settings/views/settings_menu.dart';

Widget _app(Widget child, {required bool dark}) => MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

Color? _noticeFill(WidgetTester tester) {
  final panel = tester.widget<Container>(
    find.descendant(of: find.byType(AppNotice), matching: find.byType(Container)).first,
  );
  return (panel.decoration as BoxDecoration?)?.color;
}

void main() {
  group('AppNotice', () {
    testWidgets('sits on a deep tint in dark mode and a pale one in light mode', (tester) async {
      const notice = AppNotice(message: 'Saving sends this service back for approval.');

      await tester.pumpWidget(_app(notice, dark: true));
      expect(_noticeFill(tester), AppColors.infoBgDark);

      await tester.pumpWidget(_app(notice, dark: false));
      await tester.pumpAndSettle();
      expect(_noticeFill(tester), AppColors.infoBg);
    });

    testWidgets('each tone has its own colour', (tester) async {
      await tester.pumpWidget(_app(const AppNotice(tone: NoticeTone.error, message: 'Not approved'), dark: true));
      expect(_noticeFill(tester), AppColors.errorBgDark);
    });
  });

  group('SettingsGroup', () {
    testWidgets('stays closed until tapped, then shows its items', (tester) async {
      await tester.pumpWidget(_app(
        SettingsGroup(
          icon: AppIcons.person_outline_rounded,
          title: 'Account',
          summary: 'Profile, ID verification, password',
          children: [
            SettingsTile(icon: AppIcons.lock_outline_rounded, label: 'Change password', onTap: () {}),
          ],
        ),
        dark: false,
      ));

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Profile, ID verification, password'), findsOneWidget);
      expect(find.text('Change password'), findsNothing);

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Change password'), findsOneWidget);

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Change password'), findsNothing);
    });
  });

  test('screens take tints from the theme-aware palette, not fixed light ones', () {
    // A fixed `AppColors.*Bg` stays pale in dark mode — the white notice with
    // light text this guards against. Use `context.*BgColor` or AppNotice.
    final fixedTint = RegExp(r'AppColors\.(infoBg|successBg|warningBg|errorBg|secondarySoft)\b');
    const allowed = {
      'lib/core/constants/app_colors.dart',
      'lib/core/theme/app_palette.dart',
      // The theme itself, which already picks per brightness.
      'lib/core/theme/app_theme.dart',
      // A light disc on the always-dark hero card, in both modes.
      'lib/features/payments/views/payment_details_screen.dart',
    };

    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart'))
          if (!allowed.contains(file.path.replaceAll(r'\', '/')))
            for (final (i, line) in file.readAsLinesSync().indexed)
              if (fixedTint.hasMatch(line)) '${file.path}:${i + 1}: ${line.trim()}',
    ];

    expect(offenders, isEmpty);
  });
}
