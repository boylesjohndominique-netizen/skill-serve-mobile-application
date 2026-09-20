import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/feedback/app_bottom_sheet.dart';
import '../../../../core/widgets/misc/app_icon.dart';
import '../../../provider/models/provider_availability_model.dart';
import '../../models/category_model.dart';
import '../../models/discovery_filters.dart';

/// Opens the discovery filter sheet and resolves with the filters the user
/// applied, or `null` when they dismissed it without applying.
///
/// [showProviderFilters] hides recognition and availability on surfaces that
/// list services only, since both are provider-level filters.
Future<DiscoveryFilters?> showDiscoveryFilterSheet(
  BuildContext context, {
  required DiscoveryFilters filters,
  required List<CategoryModel> categories,
  bool showProviderFilters = true,
}) {
  return AppBottomSheet.show<DiscoveryFilters>(
    context,
    child: _DiscoveryFilterSheet(
      filters: filters,
      categories: categories,
      showProviderFilters: showProviderFilters,
    ),
  );
}

class _DiscoveryFilterSheet extends StatefulWidget {
  final DiscoveryFilters filters;
  final List<CategoryModel> categories;
  final bool showProviderFilters;

  const _DiscoveryFilterSheet({
    required this.filters,
    required this.categories,
    required this.showProviderFilters,
  });

  @override
  State<_DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

class _DiscoveryFilterSheetState extends State<_DiscoveryFilterSheet> {
  late DiscoveryFilters _draft = widget.filters;

  @override
  Widget build(BuildContext context) {
    final sorts = DiscoverySort.values
        .where((sort) => widget.showProviderFilters ? sort.appliesToProviders : sort.appliesToServices)
        .toList();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: AppTextStyles.headlineMedium),
              TextButton(
                onPressed: _draft.isEmpty ? null : () => setState(() => _draft = const DiscoveryFilters()),
                child: const Text('Reset'),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.categories.isNotEmpty) ...[
                    const _FilterLabel('Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _draft.category == null,
                          onSelected: () => setState(() => _draft = _draft.copyWith(clearCategory: true)),
                        ),
                        for (final category in widget.categories)
                          _FilterChip(
                            label: category.name,
                            selected: _draft.category?.id == category.id,
                            onSelected: () => setState(() => _draft = _draft.copyWith(category: category)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],
                  const _FilterLabel('Minimum rating'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Any',
                        selected: _draft.minRating == null,
                        onSelected: () => setState(() => _draft = _draft.copyWith(clearMinRating: true)),
                      ),
                      for (final rating in DiscoveryFilters.ratingOptions)
                        _FilterChip(
                          label: DiscoveryFilters.ratingLabel(rating),
                          icon: AppIcons.star_rounded,
                          selected: _draft.minRating == rating,
                          onSelected: () => setState(() => _draft = _draft.copyWith(minRating: rating)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  if (widget.showProviderFilters) ...[
                    const _FilterLabel('Recognition and availability'),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _draft.featuredOnly,
                      onChanged: (value) => setState(() => _draft = _draft.copyWith(featuredOnly: value)),
                      title: Text('Featured providers only', style: AppTextStyles.bodyLarge),
                      subtitle: Text('Highlighted by the SkillServe team', style: AppTextStyles.bodySmall),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _draft.availableOnly,
                      onChanged: (value) => setState(() => _draft = _draft.copyWith(availableOnly: value)),
                      title: Text('Available to book now', style: AppTextStyles.bodyLarge),
                      subtitle: Text('Has at least one service you can book online', style: AppTextStyles.bodySmall),
                    ),
                    const _FilterLabel('Works on'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'Any day',
                          selected: _draft.availableDay == null,
                          onSelected: () => setState(() => _draft = _draft.copyWith(clearAvailableDay: true)),
                        ),
                        for (var day = 0; day < ProviderAvailabilityModel.dayNames.length; day++)
                          _FilterChip(
                            label: ProviderAvailabilityModel.dayNames[day].substring(0, 3),
                            selected: _draft.availableDay == day,
                            onSelected: () => setState(() => _draft = _draft.copyWith(availableDay: day)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],
                  const _FilterLabel('Sort by'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sort in sorts)
                        _FilterChip(
                          label: sort.label,
                          selected: _draft.sort == sort,
                          onSelected: () => setState(() => _draft = _draft.copyWith(sort: sort)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedAppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Apply',
                  onPressed: () => Navigator.of(context).pop(_draft),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(text.toUpperCase(), style: AppTextStyles.eyebrow),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final AppIconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      avatar: icon == null
          ? null
          : AppIcon(icon!, size: 14, color: selected ? AppColors.primary : AppColors.star),
      label: Text(label),
      labelStyle: AppTextStyles.label.copyWith(
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.primary : null,
      ),
      selectedColor: AppColors.secondary,
    );
  }
}
