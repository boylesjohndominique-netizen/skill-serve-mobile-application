import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

/// Secondary button — ink-navy fill, used for actions that matter but
/// shouldn't compete visually with the brass primary action.
/// Includes press-scale micro-animation for tactile feedback.
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppAnimations.pressScale : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: Colors.white), const SizedBox(width: 8)],
              Text(widget.label, style: AppTextStyles.button.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
    return widget.fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
