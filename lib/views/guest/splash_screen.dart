import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// First screen shown on launch. In a real build this would check for a
/// persisted session (SharedPreferences) and route straight to the right
/// shell; here it always routes to Onboarding after a short brand beat.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
            const SizedBox(height: 22),
            Text(
              'SkillLink',
              style: AppTextStyles.onDark(AppTextStyles.displayMedium),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 6),
            Text(
              'Trusted talent, made visible.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMutedDark),
            ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
