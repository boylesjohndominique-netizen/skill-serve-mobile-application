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
/// Rendered with the brand lime gradient (`AppColors.brassGradient`, 135°
/// #C7F33C → #A5CF25 — the name predates the lime palette), charcoal text,
/// and a soft glow shadow. Pressing scales the button down
/// (0.97) with a smooth cubic-bezier curve for tactile feedback.
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

  bool get _disabled => widget.isLoading || widget.onPressed == null;

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
            boxShadow: _disabled
                ? []
                : [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: _pressed ? 0.3 : 0.45),
                      blurRadius: _pressed ? 10 : 24,
                      offset: Offset(0, _pressed ? 2 : 8),
                    ),
                  ],
          ),
          child: Opacity(
            opacity: _disabled ? 0.55 : 1.0,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.brassGradient,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: InkWell(
                  onTap: _disabled ? null : widget.onPressed,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  splashColor: Colors.black.withValues(alpha: 0.14),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return widget.fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
