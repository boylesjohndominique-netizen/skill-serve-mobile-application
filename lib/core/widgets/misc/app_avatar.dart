import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../feedback/shimmer_placeholder.dart';

/// Shared initials/photo circle — the standard avatar across the app.
/// Tones: ink (default) or brass. Falls back to initials, then an icon.
class AppAvatar extends StatelessWidget {
  /// Explicit initials ("JD"). When null, initials are derived from [name].
  final String? initials;

  /// Full name used to derive initials when [initials] is not provided.
  final String? name;

  /// Optional photo URL (rendered via a single cached_network_image load).
  final String? photoUrl;

  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final AppIconData? fallbackIcon;

  const AppAvatar({
    super.key,
    this.initials,
    this.name,
    this.photoUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.fallbackIcon,
  });

  static String deriveInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final fg = foregroundColor ?? Colors.white;
    final label = initials ?? deriveInitials(name);

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: CachedNetworkImage(
            imageUrl: photoUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => ShimmerPlaceholder(
              width: radius * 2,
              height: radius * 2,
              borderRadius: radius,
            ),
            errorWidget: (_, __, ___) => _fallback(bg, fg, label),
          ),
        ),
      );
    }
    return _fallback(bg, fg, label);
  }

  Widget _fallback(Color bg, Color fg, String label) {
    if (fallbackIcon != null && label == '?') {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: AppIcon(fallbackIcon, size: radius * 0.9, color: fg),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        label,
        style: AppTextStyles.titleMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.62,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
