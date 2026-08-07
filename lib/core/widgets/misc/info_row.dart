import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Label / value row used in booking summaries, receipts, and detail cards.
/// Optionally highlights [value] with the mono face when it's an ID, price,
/// or reference number.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final AppIconData? icon;
  final bool mono;
  final bool emphasize;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.mono = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueStyle = mono
        ? AppTextStyles.monoMd.copyWith(
            color: emphasize ? AppColors.secondary : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          )
        : AppTextStyles.titleMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            AppIcon(icon, size: 16, color: AppColors.neutral300),
            const SizedBox(width: AppSizes.sm),
          ],
          Expanded(
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          const SizedBox(width: AppSizes.md),
          Flexible(
            child: Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
