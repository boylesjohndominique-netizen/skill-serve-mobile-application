import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Low-emphasis outlined button for secondary/tertiary actions
/// (e.g. "Cancel", "View details").
/// Includes press-scale micro-animation for tactile feedback.
class OutlinedAppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppIconData? icon;
  final bool fullWidth;
  final Color? color;

  const OutlinedAppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.color,
  });

  @override
  State<OutlinedAppButton> createState() => _OutlinedAppButtonState();
}

class _OutlinedAppButtonState extends State<OutlinedAppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppColors.textPrimary;
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppAnimations.pressScale : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        child: OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(foregroundColor: c, side: BorderSide(color: c.withValues(alpha: 0.25))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[AppIcon(widget.icon, size: 18, color: c), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  widget.label,
                  style: AppTextStyles.button.copyWith(color: c),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return widget.fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
