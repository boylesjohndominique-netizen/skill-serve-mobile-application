import 'package:flutter/material.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/misc/app_icon.dart';

/// The Profile tab's menu, shared by the customer and provider screens: each
/// category is a card that opens to show its items, so the tab stays short.
///
/// Colours come from the theme-aware palette, so the menu reads the same in
/// light and dark mode.
class SettingsGroup extends StatefulWidget {
  final AppIconData icon;
  final String title;

  /// What is inside, shown under the title while the group is closed.
  final String summary;
  final List<Widget> children;
  final bool initiallyExpanded;

  const SettingsGroup({
    super.key,
    required this.icon,
    required this.title,
    required this.summary,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<SettingsGroup> createState() => _SettingsGroupState();
}

class _SettingsGroupState extends State<SettingsGroup> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final line = (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: line, width: 0.8),
          ),
          child: Column(
            children: [
              Semantics(
                button: true,
                expanded: _expanded,
                label: '${widget.title}. ${widget.summary}',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: context.accentSoftColor,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                          alignment: Alignment.center,
                          child: AppIcon(widget.icon, size: 19, color: context.onAccentSoftColor),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title, style: AppTextStyles.titleMedium),
                              Text(
                                widget.summary,
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.25 : 0,
                          duration: AppAnimations.md,
                          curve: AppAnimations.defaultCurve,
                          child: AppIcon(AppIcons.chevron_right_rounded, color: context.textMutedColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: AppAnimations.md,
                curve: AppAnimations.defaultCurve,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Column(
                        children: [
                          Divider(height: 1, thickness: 0.8, color: line),
                          for (var i = 0; i < widget.children.length; i++) ...[
                            if (i > 0)
                              Divider(height: 1, thickness: 0.6, indent: 52, color: line),
                            widget.children[i],
                          ],
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One item inside a [SettingsGroup]. [onTap] null disables it (e.g. while
/// the profile it needs is loading).
class SettingsTile extends StatelessWidget {
  final AppIconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.errorColor : context.textPrimaryColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      minLeadingWidth: 24,
      leading: AppIcon(icon, color: danger ? context.errorColor : context.textSecondaryColor, size: 20),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: color)),
      trailing: danger ? null : AppIcon(AppIcons.chevron_right_rounded, color: context.textMutedColor, size: 18),
      onTap: onTap,
    );
  }
}

/// An on/off item inside a [SettingsGroup].
class SettingsSwitchTile extends StatelessWidget {
  final AppIconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      secondary: AppIcon(icon, color: context.textSecondaryColor, size: 20),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: context.textPrimaryColor)),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Log out (or Log in, for a guest): kept outside the groups so it is always
/// one tap away.
class SettingsSessionButton extends StatelessWidget {
  final bool signedIn;
  final VoidCallback onPressed;

  const SettingsSessionButton({super.key, required this.signedIn, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = signedIn ? context.errorColor : context.accentInk;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: AppIcon(signedIn ? AppIcons.logout_rounded : AppIcons.login_rounded, color: color, size: 18),
        label: Text(signedIn ? 'Log out' : 'Log in', style: AppTextStyles.button.copyWith(color: color)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
      ),
    );
  }
}
