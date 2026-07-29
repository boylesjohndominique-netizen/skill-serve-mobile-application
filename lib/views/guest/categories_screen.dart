import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/marketplace_controller.dart';
import '../../core/constants/app_sizes.dart';
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
                  );
                },
              ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onTap;

  const _CategoryTile({required this.name, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.work_outline_rounded, color: Color(0xFFC9852E), size: 26),
              const SizedBox(height: 8),
              Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('$count pros', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
