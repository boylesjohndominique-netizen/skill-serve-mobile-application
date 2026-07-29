import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/inputs/app_search_bar.dart';

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

const _faqs = [
  _Faq('How do I book a service?', 'Browse a category or search for a provider, view their profile, then tap "Book now" to choose a date and time.'),
  _Faq('How are providers verified?', 'Every provider submits a valid ID and relevant certificates, which our admin team reviews before their profile goes live.'),
  _Faq('Can I cancel a booking?', 'Yes — open the booking from your Booking History and tap "Cancel booking." Both you and the provider will be notified.'),
  _Faq('How do I message a provider?', 'From a provider\'s profile, tap "Message" to start a conversation before or after booking.'),
  _Faq('What if I have an issue with a completed job?', 'You can leave a review reflecting your experience, or contact support directly for unresolved disputes.'),
  _Faq('How do providers get paid?', 'Payment handling is managed outside the app for now — coordinate directly with your provider upon completion.'),
];

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Text('How can we help?', style: AppTextStyles.displayMedium)
                .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: AppSizes.md),
            const AppSearchBar(hint: 'Search help articles…')
                .animate().fadeIn(delay: 80.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.xl),
            Text('Frequently asked questions', style: AppTextStyles.titleLarge)
                .animate().fadeIn(delay: 150.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.sm),
            for (var i = 0; i < _faqs.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
                  boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(_faqs[i].question, style: AppTextStyles.titleMedium),
                    childrenPadding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.md),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(_faqs[i].answer, style: AppTextStyles.bodyLarge)],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 200 + i * 60), duration: 350.ms)
                  .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSizes.lg),
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded, color: AppColors.secondary, size: 28),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Still need help?', style: AppTextStyles.onDark(AppTextStyles.titleMedium)),
                        Text('Our support team responds within a day.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),
          ],
        ),
      ),
    );
  }
}
