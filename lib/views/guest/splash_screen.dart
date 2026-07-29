import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// First screen shown on launch — brand beat with expanding ring and
/// breathing background gradient.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
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
            Stack(
              alignment: Alignment.center,
              children: [
                // Expanding ring
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2), width: 2),
                  ),
                )
                    .animate()
                    .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.0, 1.0), duration: 800.ms, curve: Curves.easeOutCubic)
                    .fadeIn(duration: 400.ms)
                    .then()
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.15, duration: 1500.ms, curve: Curves.easeInOut),
                // Logo circle
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack)
                    .fadeIn(),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'SkillLink',
              style: AppTextStyles.onDark(AppTextStyles.displayMedium),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 6),
            Text(
              'Trusted talent, made visible.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMutedDark),
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
