import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/maintenance_state.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../services/platform_service.dart';
import '../../../core/theme/app_palette.dart';

/// Covers the app with a maintenance notice while the platform is in
/// maintenance mode, and lifts it once the platform endpoint says it is over.
class MaintenanceGate extends StatelessWidget {
  final Widget child;
  const MaintenanceGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: MaintenanceState.active,
      builder: (context, active, _) => Stack(
        children: [
          child,
          if (active) const Positioned.fill(child: _MaintenanceScreen()),
        ],
      ),
    );
  }
}

class _MaintenanceScreen extends StatefulWidget {
  const _MaintenanceScreen();

  @override
  State<_MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<_MaintenanceScreen> {
  bool _checking = false;
  String? _stillDown;

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _stillDown = null;
    });
    try {
      final platform = await PlatformService().get();
      if (!platform.maintenanceMode) {
        MaintenanceState.active.value = false;
        return;
      }
      _stillDown = 'Still under maintenance. Please check again in a few minutes.';
    } catch (_) {
      _stillDown = 'Could not reach SkillServe. Check your connection and try again.';
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.backgroundDark : AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(AppIcons.handyman_outlined, size: 56, color: context.accentInk),
              const SizedBox(height: AppSizes.lg),
              Text('We\'ll be right back', style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.sm),
              Text(
                'SkillServe is down for scheduled maintenance. Your bookings and messages are safe.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_stillDown != null) ...[
                const SizedBox(height: AppSizes.md),
                Text(_stillDown!, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              ],
              const SizedBox(height: AppSizes.xl),
              PrimaryButton(
                label: 'Check again',
                icon: AppIcons.refresh_rounded,
                isLoading: _checking,
                onPressed: _checking ? null : _check,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
