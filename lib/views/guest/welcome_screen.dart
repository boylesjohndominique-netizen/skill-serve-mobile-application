import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
              // Logo with glow pulse
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15), width: 2),
                    ),
                  )
                      .animate()
                      .scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.easeOutBack)
                      .fadeIn()
                      .then()
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 1.0, end: 1.1, duration: 2000.ms, curve: Curves.easeInOut),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                    child: const AppIcon(AppIcons.check_rounded, color: AppColors.primary, size: 46),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              Text(
                'Welcome to SkillServe',
                style: AppTextStyles.onDark(AppTextStyles.displayLarge),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.12, end: 0),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Bridging service accessibility and talent visibility — one booking at a time.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMutedDark),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'Create an account',
                onPressed: () => context.go('/register'),
              ).animate().fadeIn(delay: 400.ms, duration: 350.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutBack),
              const SizedBox(height: AppSizes.md),
              OutlinedAppButton(
                label: 'Log in',
                color: Colors.white,
                onPressed: () => context.go('/login'),
              ).animate().fadeIn(delay: 480.ms, duration: 350.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutBack),
              const SizedBox(height: AppSizes.lg),
              TextButton(
                onPressed: () => context.go('/browse'),
                child: Text(
                  'Continue browsing as guest',
                  style: AppTextStyles.button.copyWith(color: AppColors.textMutedDark),
                ),
              ).animate().fadeIn(delay: 550.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
