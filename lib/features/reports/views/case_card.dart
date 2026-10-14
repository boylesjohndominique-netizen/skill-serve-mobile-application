import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/misc/status_badge.dart';

/// One escalated case — shared by reports and disputes, which carry the same
/// shape: what it is about, where it got to, and what support decided.
class CaseCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String status;
  final String body;
  final String? outcome;
  final DateTime? openedAt;
  final DateTime? decidedAt;
  final String reference;
  final VoidCallback? onTap;

  /// Extra content under the body — the report's photos, or the dispute
  /// evidence strip.
  final Widget? footer;

  const CaseCard({
    super.key,
    required this.title,
    required this.status,
    required this.body,
    required this.reference,
    this.subtitle,
    this.outcome,
    this.openedAt,
    this.decidedAt,
    this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
          boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: AppSizes.sm),
                StatusBadge.fromStatus(status),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: AppSizes.sm),
            Text(body, style: AppTextStyles.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (outcome != null && outcome!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Support response',
                        style: AppTextStyles.label.copyWith(color: AppColors.neutral400)),
                    const SizedBox(height: 2),
                    Text(outcome!, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: AppSizes.md),
              footer!,
            ],
            Divider(height: AppSizes.lg, color: lineColor),
            Row(
              children: [
                if (reference.isNotEmpty)
                  Text(reference, style: AppTextStyles.monoSm),
                const Spacer(),
                Text(
                  decidedAt != null
                      ? 'Updated ${Formatters.relative(decidedAt!)}'
                      : openedAt != null
                          ? 'Filed ${Formatters.relative(openedAt!)}'
                          : '',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
