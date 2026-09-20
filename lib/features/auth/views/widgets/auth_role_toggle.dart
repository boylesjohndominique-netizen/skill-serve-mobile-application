import 'package:flutter/material.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/misc/app_icon.dart';
import '../../models/user_model.dart';

/// "I need a service" / "I offer a service" segmented control, shared by
/// every sign-up form so the choice looks and behaves the same whether the
/// account starts from an email address or from Google.
class AuthRoleToggle extends StatelessWidget {
  final UserRole role;
  final void Function(UserRole) onChanged;

  /// False while a submission is in flight, so the role cannot change
  /// under the request that is already using it.
  final bool enabled;

  const AuthRoleToggle({
    super.key,
    required this.role,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'I need a service',
              value: UserRole.client,
              icon: AppIcons.person_search_rounded,
              selected: role == UserRole.client,
              enabled: enabled,
              onTap: onChanged,
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'I offer a service',
              value: UserRole.provider,
              icon: AppIcons.handyman_rounded,
              selected: role == UserRole.provider,
              enabled: enabled,
              onTap: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final UserRole value;
  final AppIconData icon;
  final bool selected;
  final bool enabled;
  final void Function(UserRole) onTap;

  const _Tab({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? () => onTap(value) : null,
        child: AnimatedContainer(
          duration: AppAnimations.md,
          curve: AppAnimations.defaultCurve,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: selected ? 1.1 : 1.0,
                duration: AppAnimations.md,
                curve: AppAnimations.springCurve,
                child: AppIcon(icon,
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
