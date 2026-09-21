import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/inputs/app_search_bar.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

const _faqs = [
  _Faq('How do I book a service?', 'Browse a category or search for a provider, view their profile, then tap "Book now" to choose a date and time.'),
  _Faq('How are providers verified?', 'Every provider submits a valid ID and relevant certificates, which our admin team reviews before their profile goes live.'),
  _Faq('Can I cancel a booking?', 'Yes — open the booking from your Booking History and tap "Cancel booking." Both you and the provider will be notified.'),
  _Faq('Can I change the date or time of a booking?', 'Yes, until the job starts. Open the booking and tap "Reschedule" to pick a new slot within the provider\'s hours. If the provider had already accepted, they will be asked to accept the new time.'),
  _Faq('How do I message a provider?', 'From a provider\'s profile, tap "Message" to start a conversation before or after booking.'),
  _Faq('What if I have an issue with a completed job?', 'You can leave a review reflecting your experience, or contact support directly for unresolved disputes.'),
  _Faq('How do providers get paid?', 'You pay the provider directly, using the method you chose when booking (cash, GCash, …). Once they receive it, the provider marks the job as paid in the app, and you can see the payment under Payments.'),
  _Faq('How do I save a provider for later?', 'Tap the heart on a provider\'s card or profile. Saved providers appear under Favorites and stay there across devices while you are signed in.'),
];

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _query = '';

  /// FAQs whose question or answer contains every word typed, ignoring case.
  List<_Faq> get _matches {
    final words = _query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return _faqs;
    return _faqs.where((faq) {
      final text = '${faq.question} ${faq.answer}'.toLowerCase();
      return words.every(text.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _matches;
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
            AppSearchBar(
              hint: 'Search help articles…',
              onChanged: (value) => setState(() => _query = value),
            ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.xl),
            Text(_query.trim().isEmpty ? 'Frequently asked questions' : 'Results',
                    style: AppTextStyles.titleLarge)
                .animate().fadeIn(delay: 150.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.sm),
            if (faqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                child: Text(
                  'No articles match "${_query.trim()}". Try other words, or open a support ticket below.',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            for (var i = 0; i < faqs.length; i++)
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
                    // A new result set must not inherit another row's open state.
                    key: ValueKey(faqs[i].question),
                    title: Text(faqs[i].question, style: AppTextStyles.titleMedium),
                    childrenPadding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.md),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(faqs[i].answer, style: AppTextStyles.bodyLarge)],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 200 + i * 60), duration: 350.ms)
                  .slideY(begin: 0.05, end: 0),
            const SizedBox(height: AppSizes.lg),
            // Signed-in customers and providers both raise tickets; a guest is
            // pointed at the contact details instead.
            _StillNeedHelpCard(
              canRaiseTickets: context.read<AuthController>().status == AuthStatus.authenticated,
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),
          ],
        ),
      ),
    );
  }
}

/// The Help Center's route into Support.
class _StillNeedHelpCard extends StatelessWidget {
  final bool canRaiseTickets;
  const _StillNeedHelpCard({required this.canRaiseTickets});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => context.push(canRaiseTickets ? '/support/tickets' : '/contact'),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const AppIcon(AppIcons.support_agent_rounded, color: AppColors.secondary, size: 28),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Still need help?',
                        style: AppTextStyles.onDark(AppTextStyles.titleMedium)),
                    Text(
                      canRaiseTickets
                          ? 'Open a support ticket and we will reply in the app.'
                          : 'Get in touch with our support team.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark),
                    ),
                  ],
                ),
              ),
              const AppIcon(AppIcons.chevron_right_rounded,
                  color: AppColors.secondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
