import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../constants/app_icons.dart';

/// Drop-in replacement for Flutter's [Icon] widget that renders HugeIcons.
///
/// Accepts the same usage as [Icon] (`AppIcon(AppIcons.home_rounded,
/// size: 20, color: X)`) so the rest of the codebase stays unchanged in
/// shape — only the glyph source differs.
class AppIcon extends StatelessWidget {
  /// The HugeIcons glyph (SVG path data) to render.
  final AppIconData? icon;

  /// Icon size in logical pixels.
  final double? size;

  /// Icon color.
  final Color? color;

  /// Stroke width for crisp vector rendering.
  final double? strokeWidth;

  const AppIcon(this.icon, {super.key, this.size, this.color, this.strokeWidth});

  @override
  Widget build(BuildContext context) {
    final i = icon;
    if (i == null) return const SizedBox.shrink();
    return HugeIcon(
      icon: i,
      size: size ?? 20.0,
      color: color ?? IconTheme.of(context).color ?? const Color(0xFF1C2128),
      strokeWidth: strokeWidth ?? 1.8,
    );
  }
}
