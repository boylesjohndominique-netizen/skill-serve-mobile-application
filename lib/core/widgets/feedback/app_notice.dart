import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_palette.dart';
import '../misc/app_icon.dart';

/// What a notice is about; decides its colour and default icon.
enum NoticeTone { info, success, warning, error }

/// The one inline notice of the app: a tinted panel with an icon, an
/// optional title, the message, and an optional action below it.
///
/// Colours come from the theme-aware palette, so the same notice reads right
/// in light and dark mode — never build a notice from fixed `AppColors.*Bg`
/// values, which stay pale (and glare) on a dark screen.
class AppNotice extends StatelessWidget {
  final NoticeTone tone;
  final String? title;
  final String? message;

  /// Rich content in place of [message], e.g. text with a link.
  final Widget? content;
  final AppIconData? icon;
  final Widget? action;

  const AppNotice({
    super.key,
    this.tone = NoticeTone.info,
    this.title,
    this.message,
    this.content,
    this.icon,
    this.action,
  }) : assert(message != null || content != null || title != null, 'A notice needs something to say.');

  /// The foreground colour for [tone] — for callers that colour extra text
  /// inside [content] to match.
  static Color colorFor(BuildContext context, NoticeTone tone) => switch (tone) {
        NoticeTone.info => context.infoColor,
        NoticeTone.success => context.successColor,
        NoticeTone.warning => context.warningColor,
        NoticeTone.error => context.errorColor,
      };

  static Color backgroundFor(BuildContext context, NoticeTone tone) => switch (tone) {
        NoticeTone.info => context.infoBgColor,
        NoticeTone.success => context.successBgColor,
        NoticeTone.warning => context.warningBgColor,
        NoticeTone.error => context.errorBgColor,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(context, tone);
    final glyph = icon ??
        switch (tone) {
          NoticeTone.info => AppIcons.info_outline_rounded,
          NoticeTone.success => AppIcons.check_circle_rounded,
          NoticeTone.warning => AppIcons.warning_amber_rounded,
          NoticeTone.error => AppIcons.error_rounded,
        };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: backgroundFor(context, tone),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(glyph, color: color, size: 18),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!, style: AppTextStyles.titleMedium.copyWith(color: color)),
                if (title != null && (message != null || content != null)) const SizedBox(height: 2),
                if (content != null)
                  content!
                else if (message != null)
                  Text(message!, style: AppTextStyles.bodySmall.copyWith(color: color)),
                if (action != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
