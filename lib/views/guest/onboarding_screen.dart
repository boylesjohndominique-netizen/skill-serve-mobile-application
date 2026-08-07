import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

class _OnboardSlide {
  final AppIconData icon;
  final String title;
  final String description;
  const _OnboardSlide({required this.icon, required this.title, required this.description});
}

const _slides = [
  _OnboardSlide(
    icon: AppIcons.handyman_rounded,
    title: 'Find trusted local talent',
    description: 'Browse verified plumbers, electricians, tutors, designers, and more — all background-checked.',
  ),
  _OnboardSlide(
    icon: AppIcons.event_available_rounded,
    title: 'Book in a few taps',
    description: 'Pick a service, choose a schedule, and confirm your booking — no back-and-forth calls needed.',
  ),
  _OnboardSlide(
    icon: AppIcons.verified_user_rounded,
    title: 'Verified & rated providers',
    description: 'Every provider is ID-verified and rated by real clients, so you always know who you\'re hiring.',
  ),
  _OnboardSlide(
    icon: AppIcons.storefront_rounded,
    title: 'Grow your service business',
    description: 'Providers get a public profile, booking calendar, and direct messaging — all in one app.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  void _next() {
    if (_index == _slides.length - 1) {
      context.go('/welcome');
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: TextButton(
                  onPressed: () => context.go('/welcome'),
                  child: Text('Skip', style: AppTextStyles.button.copyWith(color: AppColors.textMuted)),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with glow ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow ring
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(46),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.15),
                                  width: 2,
                                ),
                              ),
                            )
                                .animate(key: ValueKey('ring$i'))
                                .fadeIn(duration: 300.ms)
                                .scale(begin: const Offset(0.85, 0.85)),
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: AppIcon(slide.icon, size: 68, color: AppColors.secondary),
                            )
                                .animate(key: ValueKey(i))
                                .fadeIn(duration: 350.ms)
                                .scale(begin: const Offset(0.88, 0.88), curve: Curves.easeOutBack),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xxl),
                        Text(slide.title, style: AppTextStyles.displayMedium, textAlign: TextAlign.center)
                            .animate(key: ValueKey('t$i'))
                            .fadeIn(delay: 100.ms, duration: 350.ms)
                            .slideY(begin: 0.12, end: 0),
                        const SizedBox(height: AppSizes.sm),
                        Text(slide.description, style: AppTextStyles.bodyLarge, textAlign: TextAlign.center)
                            .animate(key: ValueKey('d$i'))
                            .fadeIn(delay: 200.ms, duration: 350.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dot indicators with spring physics
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.secondary : AppColors.neutral200,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: i == _index
                        ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 6)]
                        : [],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: PrimaryButton(
                label: _index == _slides.length - 1 ? 'Get started' : 'Next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
