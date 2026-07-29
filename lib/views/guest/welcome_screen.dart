import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 46),
              ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack),
              const SizedBox(height: AppSizes.xl),
              Text(
                'Welcome to SkillLink',
                style: AppTextStyles.onDark(AppTextStyles.displayLarge),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15, end: 0),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Bridging service accessibility and talent visibility — one booking at a time.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMutedDark),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 250.ms),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'Create an account',
                onPressed: () => context.go('/register'),
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: AppSizes.md),
              OutlinedAppButton(
                label: 'Log in',
                color: Colors.white,
                onPressed: () => context.go('/login'),
              ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: AppSizes.lg),
              TextButton(
                onPressed: () => context.go('/browse'),
                child: Text(
                  'Continue browsing as guest',
                  style: AppTextStyles.button.copyWith(color: AppColors.textMutedDark),
                ),
              ).animate().fadeIn(delay: 480.ms),
            ],
          ),
        ),
      ),
    );
  }
}
