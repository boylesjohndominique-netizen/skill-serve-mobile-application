import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:skillserve_mobile/core/theme/app_theme.dart';
import 'package:skillserve_mobile/core/widgets/misc/app_icon.dart';
import 'package:skillserve_mobile/features/auth/controllers/auth_controller.dart';
import 'package:skillserve_mobile/features/booking/controllers/booking_controller.dart';
import 'package:skillserve_mobile/features/booking/controllers/provider_booking_controller.dart';
import 'package:skillserve_mobile/features/identity/controllers/identity_controller.dart';
import 'package:skillserve_mobile/features/marketplace/controllers/discovery_controller.dart';
import 'package:skillserve_mobile/features/marketplace/controllers/favorites_controller.dart';
import 'package:skillserve_mobile/features/marketplace/controllers/marketplace_controller.dart';
import 'package:skillserve_mobile/features/messaging/controllers/chat_controller.dart';
import 'package:skillserve_mobile/features/notifications/controllers/notification_controller.dart';
import 'package:skillserve_mobile/features/payments/controllers/payment_controller.dart';
import 'package:skillserve_mobile/features/provider/controllers/portfolio_controller.dart';
import 'package:skillserve_mobile/features/provider/controllers/provider_services_controller.dart';
import 'package:skillserve_mobile/features/reports/controllers/report_controller.dart';
import 'package:skillserve_mobile/features/settings/controllers/preferences_controller.dart';
import 'package:skillserve_mobile/routes/app_router.dart';

import 'support/scanned_identity.dart';

/// Every screen must be readable in light AND dark mode: no text or icon may
/// sit on its background at less than 3:1 contrast (the floor for large text
/// and icons; below it things genuinely "can't be seen").
///
/// Each piece of text and every icon is walked up to the first opaque
/// background actually painted behind it (Material, Card, Scaffold,
/// decorated or coloured boxes), blending translucent layers on the way.
const _routes = <String>[
  // Guest and auth
  '/welcome', '/login', '/register', '/forgot-password', '/create-password',
  '/verify-email?email=someone@example.com', '/onboarding',
  '/browse', '/categories', '/search', '/about', '/contact', '/terms', '/privacy',
  '/provider-preview/PV-100',
  // Client
  '/client', '/service-details/SV-1', '/provider-profile/PV-100', '/booking-history',
  '/favorites', '/chat-conversation/CV-0', '/payments', '/my-reports', '/notifications',
  '/reviews/PV-100', '/booking-details/BK-5000', '/help-center', '/activity-history',
  '/notification-preferences', '/privacy-settings', '/application-preferences',
  '/security-activity', '/file-report', '/identity-verification',
  // Provider
  '/provider', '/statistics', '/my-services', '/portfolio', '/calendar', '/availability',
  '/booking-requests', '/active-jobs', '/completed-jobs', '/earnings', '/commissions',
  '/gcash-details', '/withdrawal-history', '/verification-status', '/provider-badges',
];

/// Below this, text is treated as invisible.
const _minimumContrast = 3.0;

Widget _app(String route, ThemeData theme) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthController()),
      ChangeNotifierProvider(create: (_) => PreferencesController()),
      ChangeNotifierProvider(create: (_) => MarketplaceController()),
      ChangeNotifierProvider(create: (_) => DiscoveryController()),
      ChangeNotifierProvider(create: (_) => FavoritesController()),
      ChangeNotifierProvider<IdentityController>(create: (_) => scannedIdentity()),
      ChangeNotifierProvider(create: (_) => BookingController()),
      ChangeNotifierProvider(create: (_) => ProviderBookingController()),
      ChangeNotifierProvider(create: (_) => NotificationController()),
      ChangeNotifierProvider(create: (_) => ChatController()),
      ChangeNotifierProvider(create: (_) => PortfolioController()),
      ChangeNotifierProvider(create: (_) => ProviderServicesController()),
      ChangeNotifierProvider(create: (_) => PaymentController()),
      ChangeNotifierProvider(create: (_) => ReportController()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: theme,
        routerConfig: GoRouter(initialLocation: route, routes: appRoutes),
      ),
    ),
  );
}

double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// [top] painted over the opaque [bottom].
Color _over(Color top, Color bottom) {
  final a = top.a;
  return Color.from(
    alpha: 1,
    red: top.r * a + bottom.r * (1 - a),
    green: top.g * a + bottom.g * (1 - a),
    blue: top.b * a + bottom.b * (1 - a),
  );
}

Color? _decorationColor(Decoration? d) {
  if (d is BoxDecoration) {
    if (d.image != null) return null; // A photo: cannot judge.
    if (d.gradient != null) {
      final colors = d.gradient!.colors;
      // The gradient's midpoint is what most of the text sits on.
      return Color.lerp(colors.first, colors.last, 0.5);
    }
    return d.color;
  }
  if (d is ShapeDecoration) return d.color;
  return null;
}

/// The colour a widget paints behind its children, if any.
Color? _paintedColor(Widget w, Element e) {
  if (w is ColoredBox) return w.color;
  if (w is Ink) return _decorationColor(w.decoration);
  // Chips paint their own fill.
  if (w is ChoiceChip || w is FilterChip || w is InputChip) {
    final chip = w as SelectableChipAttributes;
    final theme = ChipTheme.of(e);
    final fill = w as ChipAttributes;
    return chip.selected
        ? (chip.selectedColor ?? theme.selectedColor)
        : (fill.backgroundColor ?? theme.backgroundColor);
  }
  if (w is ActionChip || w is Chip) {
    return (w as ChipAttributes).backgroundColor ?? ChipTheme.of(e).backgroundColor;
  }
  if (w is DecoratedBox && w.position == DecorationPosition.background) {
    return _decorationColor(w.decoration);
  }
  if (w is Material && w.type != MaterialType.transparency) return w.color;
  if (w is PhysicalModel) return w.color;
  return null;
}

/// The opaque colour behind [element], or null when it sits on an image.
Color? _backgroundOf(Element element) {
  final layers = <Color>[];
  Color? base;
  var onImage = false;
  element.visitAncestorElements((ancestor) {
    final w = ancestor.widget;
    if (w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).image != null) {
      onImage = true;
      return false;
    }
    if (w is Image) {
      onImage = true;
      return false;
    }
    final c = _paintedColor(w, ancestor);
    if (c == null || c.a == 0) return true;
    if (c.a >= 0.99) {
      base = c;
      return false;
    }
    layers.add(c);
    return true;
  });
  if (onImage || base == null) return null;
  var result = base!;
  for (final layer in layers.reversed) {
    result = _over(layer, result);
  }
  return result;
}

/// Readability problems on the current screen.
List<String> _lowContrast(WidgetTester tester) {
  final problems = <String>[];
  void check(Element e, Color? fg, String what) {
    if (fg == null || fg.a < 0.3) return; // Deliberately faint or hidden.
    // Skip anything Flutter does not actually lay out on screen.
    final box = e.renderObject;
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty || !box.attached) return;
    final bg = _backgroundOf(e);
    if (bg == null) return;
    final color = fg.a < 1 ? _over(fg, bg) : fg;
    final ratio = _contrast(color, bg);
    if (ratio < _minimumContrast) {
      problems.add('${ratio.toStringAsFixed(2)}:1  $what  fg=${_hex(color)} bg=${_hex(bg)}');
    }
  }

  for (final e in find.byType(RichText, skipOffstage: true).evaluate()) {
    final w = e.widget as RichText;
    final text = w.text.toPlainText().trim();
    if (text.isEmpty) continue;
    check(e, w.text.style?.color, '"${text.length > 40 ? '${text.substring(0, 40)}…' : text}"');
  }
  for (final e in find.byType(AppIcon, skipOffstage: true).evaluate()) {
    final w = e.widget as AppIcon;
    if (w.icon == null) continue;
    check(e, w.color ?? IconTheme.of(e).color ?? const Color(0xFF1C2128), 'icon');
  }
  return problems;
}

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  for (final mode in ['light', 'dark']) {
    for (final route in _routes) {
      testWidgets('$route is readable in $mode mode', (tester) async {
        tester.view.physicalSize = const Size(390, 844) * 3;
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);
        // Built inside the test: the theme loads fonts, which needs the binding.
        final theme = mode == 'dark' ? AppTheme.dark : AppTheme.light;
        await tester.pumpWidget(_app(route, theme));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 600));
        tester.takeException(); // Mock-data noise is not what this test checks.

        final problems = _lowContrast(tester).toSet().toList();
        expect(problems, isEmpty, reason: '$route ($mode):\n${problems.join('\n')}');
      });
    }
  }
}
