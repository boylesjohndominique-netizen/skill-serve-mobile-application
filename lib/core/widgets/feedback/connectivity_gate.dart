import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/outlined_app_button.dart';
import '../misc/app_icon.dart';
import '../../constants/app_icons.dart';

/// Global connectivity monitor.
///
/// Listens to connectivity changes and blocks the app behind a
/// non-dismissible "No internet connection" modal whenever the device is
/// offline. The app requires a live connection to reach the backend
/// (Render-hosted REST API), so there is no offline mode.
class ConnectivityGate {
  ConnectivityGate._();

  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isShowing = false;
  static BuildContext? _context;

  /// Start monitoring. Call once after the first frame so a Navigator is
  /// available for the modal.
  static void initialize(BuildContext context) {
    _context = context;
    // Evaluate immediately, then keep listening for changes.
    _connectivity.checkConnectivity().then(_handleResults);
    _subscription ??= _connectivity.onConnectivityChanged.listen(_handleResults);
  }

  static void _handleResults(List<ConnectivityResult> results) {
    final offline = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
    final context = _context;
    if (context == null || !context.mounted) return;

    if (offline) {
      if (!_isShowing) showNoInternetModal(context);
    } else if (_isShowing) {
      _isShowing = false;
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) navigator.pop();
    }
  }

  /// Non-dismissible modal shown whenever the device has no connectivity.
  static Future<void> showNoInternetModal(BuildContext context) {
    _context = context;
    _isShowing = true;
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'No internet connection',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 3 * animation.value,
            sigmaY: 3 * animation.value,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

        return PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(AppSizes.xl),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: AppSizes.shadowLg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.errorBg,
                        shape: BoxShape.circle,
                      ),
                      child: const AppIcon(
                        AppIcons.wifi_off_rounded,
                        size: 30,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text('No internet connection',
                        style: AppTextStyles.titleLarge),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'SkillServe needs an internet connection to reach its '
                      'servers. Please check your Wi-Fi or mobile data and '
                      'try again.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.xl),
                    PrimaryButton(
                      label: 'Try again',
                      onPressed: () async {
                        final results =
                            await _connectivity.checkConnectivity();
                        // _handleResults dismisses the modal when back online.
                        _handleResults(results);
                      },
                    ),
                    const SizedBox(height: AppSizes.sm),
                    OutlinedAppButton(
                      label: 'Open settings',
                      onPressed: () {
                        // Send the app to the background so the user lands on
                        // the OS settings home — no extra package needed.
                        SystemNavigator.pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
