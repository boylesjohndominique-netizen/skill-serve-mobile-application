import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';

/// Search field with an optional trailing filter button — used on Browse,
/// Search, and Home screens.
class AppSearchBar extends StatelessWidget {
  final String hint;
  final void Function(String)? onChanged;
  final VoidCallback? onFilterTap;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppSearchBar({
    super.key,
    this.hint = 'Search services or providers…',
    this.onChanged,
    this.onFilterTap,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: TextField(
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.neutral300),
              ),
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: AppSizes.sm),
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ],
    );
  }
}
