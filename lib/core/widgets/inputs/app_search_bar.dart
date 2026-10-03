import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// Search field with an optional trailing filter button — used on Browse,
/// Search, and Home screens.
/// Features animated shadow elevation on focus.
class AppSearchBar extends StatefulWidget {
  final String hint;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onFilterTap;

  /// Badge shown on the filter button — the number of filters applied.
  final int activeFilterCount;
  final bool readOnly;
  final VoidCallback? onTap;

  /// Pass a controller to drive the field from outside (suggestion and
  /// recent-search taps); one is created internally when omitted.
  final TextEditingController? controller;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.hint = 'Search services or providers…',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.readOnly = false,
    this.onTap,
    this.controller,
    this.autofocus = false,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  bool _focused = false;

  late final TextEditingController _controller = widget.controller ?? TextEditingController();

  bool get _ownsController => widget.controller == null;

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

    return Row(
      children: [
        Expanded(
          child: Focus(
            onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
            child: AnimatedContainer(
              duration: AppAnimations.md,
              curve: AppAnimations.defaultCurve,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: _focused ? AppColors.secondary.withValues(alpha: 0.4) : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => TextField(
                  controller: _controller,
                  readOnly: widget.readOnly,
                  autofocus: widget.autofocus,
                  textInputAction: TextInputAction.search,
                  onTap: widget.onTap,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: AnimatedRotation(
                        turns: _focused ? 0.05 : 0,
                        duration: AppAnimations.md,
                        child: AppIcon(
                          AppIcons.search_rounded,
                          size: 17,
                          strokeWidth: 1.5,
                          color: _focused ? context.accentInk : context.textMutedColor,
                        ),
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                            icon: AppIcon(AppIcons.close_rounded, size: 16, color: context.textMutedColor),
                            onPressed: () {
                              _controller.clear();
                              widget.onChanged?.call('');
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.onFilterTap != null) ...[
          const SizedBox(width: AppSizes.sm),
          Semantics(
            button: true,
            label: widget.activeFilterCount == 0
                ? 'Filters'
                : 'Filters, ${widget.activeFilterCount} applied',
            child: InkWell(
              onTap: widget.onFilterTap,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: const AppIcon(AppIcons.tune_rounded, color: Colors.white, size: 16, strokeWidth: 1.5),
                  ),
                  if (widget.activeFilterCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Text(
                          '${widget.activeFilterCount}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
