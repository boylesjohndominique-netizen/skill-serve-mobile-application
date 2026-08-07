import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Destructive action button (delete, decline, cancel, resubmit) — red fill,
/// white content, red glow, press-scale feedback. Pairs with the tone-aware
/// confirm dialogs from [AppDialog].
class DangerButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppIconData? icon;
  final bool fullWidth;

  const DangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  State<DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<DangerButton> {
  bool _pressed = false;

  bool get _disabled => widget.isLoading || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedSwitcher(
      duration: AppAnimations.fast,
      child: widget.isLoading
          ? const SizedBox(
              key: ValueKey('loading'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[AppIcon(widget.icon, size: AppSizes.iconMd, color: Colors.white), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    widget.label,
                    style: AppTextStyles.button.copyWith(color: Colors.white),
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
                      color: AppColors.error.withValues(alpha: _pressed ? 0.3 : 0.4),
                      blurRadius: _pressed ? 10 : 22,
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
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: InkWell(
                  onTap: _disabled ? null : widget.onPressed,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  splashColor: Colors.white.withValues(alpha: 0.16),
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
