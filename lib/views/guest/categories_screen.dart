import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/marketplace_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';

/// Full category grid — tapping a category routes into Browse Services
/// pre-filtered to that category.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<MarketplaceController>();
      if (controller.categories.isEmpty) controller.loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceController>();

    return Scaffold(
      appBar: AppBar(title: const Text('All Categories')),
      body: SafeArea(
        child: marketplace.isLoading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(count: 6, itemHeight: 88),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(AppSizes.pageHPad),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSizes.md,
                  crossAxisSpacing: AppSizes.md,
                  childAspectRatio: 0.82,
                ),
                itemCount: marketplace.categories.length,
                itemBuilder: (context, i) {
                  final cat = marketplace.categories[i];
                  return _CategoryTile(
                    name: cat.name,
                    count: cat.providerCount,
                    onTap: () async {
                      await context.read<MarketplaceController>().filterByCategory(cat.name);
                      if (context.mounted) context.push('/browse');
                    },
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: (i.clamp(0, 8) * 60)), duration: 350.ms)
                      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
                },
              ),
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final String name;
  final int count;
  final VoidCallback onTap;

  const _CategoryTile({required this.name, required this.count, required this.onTap});

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: lineColor.withValues(alpha: 0.6)),
            boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.work_outline_rounded, color: AppColors.secondary, size: 26),
                const SizedBox(height: 8),
                Text(widget.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${widget.count} pros', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
