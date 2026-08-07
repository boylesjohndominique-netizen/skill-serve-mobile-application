import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Primary call-to-action button. Pass [isLoading] to show an inline
/// spinner and disable interaction — this doubles as the "Loading Button"
/// variant so state stays in one place instead of two near-identical widgets.
///
/// Features a subtle press-scale micro-animation and smooth transition
/// between normal → loading state via [AnimatedSwitcher].
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppIconData? icon;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedSwitcher(
      duration: AppAnimations.fast,
      switchInCurve: AppAnimations.defaultCurve,
      switchOutCurve: AppAnimations.defaultCurve,
      child: widget.isLoading
          ? const SizedBox(
              key: ValueKey('loading'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[AppIcon(widget.icon, size: AppSizes.iconMd, color: AppColors.primary), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    widget.label,
                    style: AppTextStyles.button.copyWith(color: AppColors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    final button = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppAnimations.pressScale : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            boxShadow: widget.isLoading || widget.onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: _pressed ? 0.15 : 0.25),
                      blurRadius: _pressed ? 8 : 16,
                      offset: Offset(0, _pressed ? 2 : 6),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.6),
            ),
            child: child,
          ),
        ),
      ),
    );

    return widget.fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
