import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../models/category_model.dart';

const Map<String, IconData> _categoryIcons = {
  'plumbing': Icons.plumbing_rounded,
  'bolt': Icons.bolt_rounded,
  'school': Icons.school_rounded,
  'brush': Icons.brush_rounded,
  'photo_camera': Icons.photo_camera_rounded,
  'carpenter': Icons.carpenter_rounded,
};

/// Compact category tile used in horizontal scrollers and category grids.
class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryCard({super.key, required this.category, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[category.icon] ?? Icons.work_outline_rounded;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: selected ? AppColors.secondary : AppColors.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.secondary, size: 24),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
