import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';

import '../../provider/models/badge_model.dart';
import '../services/provider_service_service.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// P9 — Provider recognition: the badges this provider has earned, and the
/// ones still available to earn.
///
/// The platform records which badges a provider holds, not how close they
/// are to the rest, so unearned badges show their criteria rather than a
/// progress bar.
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<BadgeModel> _badges = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final badges = await ProviderServiceService().getMyBadges();
      if (!mounted) return;
      setState(() {
        _badges = badges;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e, 'We could not load your badges. Please try again.');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final badges = _badges;
    final earned = badges.where((b) => b.earned).toList();
    final next = badges.where((b) => !b.earned).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Badges')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.pageHPad),
            child: ShimmerCardList(itemHeight: 88),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Badges')),
        body: SafeArea(child: ErrorState(message: _error!, onRetry: _load)),
      );
    }

    if (badges.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Badges')),
        body: const SafeArea(
          child: EmptyState(
            icon: AppIcons.workspace_premium_rounded,
            title: 'No badges yet',
            message:
                'SkillServe has not published any recognition badges. Check back soon.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Badges')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.brassGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: AppIcon(
                    earned.isNotEmpty ? earned.first.icon : AppIcons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(width: AppSizes.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${earned.length} of ${badges.length} badges earned', style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        child: LinearProgressIndicator(
                          value: badges.isEmpty ? 0 : earned.length / badges.length,
                          minHeight: 8,
                          backgroundColor: isDark ? AppColors.surfaceAltDark : AppColors.neutral100,
                          valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Keep completing jobs and reviews to earn more.', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: AppSizes.xl),
            Text('Next to earn', style: AppTextStyles.titleLarge)
                .animate().fadeIn(delay: 150.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.md),
            if (next.isEmpty)
              Text('You\'ve earned every badge — incredible!', style: AppTextStyles.bodyLarge)
                  .animate().fadeIn(delay: 200.ms, duration: 300.ms)
            else
              for (var i = 0; i < next.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: _NextBadgeCard(badge: next[i], index: i),
                ),

            if (earned.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              Text('Earned badges', style: AppTextStyles.titleLarge)
                  .animate().fadeIn(delay: 250.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.md),
              for (var i = 0; i < earned.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: _EarnedBadgeCard(badge: earned[i], index: i),
                ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NextBadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final int index;

  const _NextBadgeCard({required this.badge, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
        boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: badge.color.withValues(alpha: 0.4), width: 1.2),
            ),
            child: AppIcon(badge.icon, color: badge.color, size: 22),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(badge.criteria, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 200 + index * 70), duration: 350.ms)
        .slideY(begin: 0.06, end: 0);
  }
}

class _EarnedBadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final int index;

  const _EarnedBadgeCard({required this.badge, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: badge.color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [badge.color, badge.color.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: AppIcon(badge.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(badge.criteria, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const AppIcon(AppIcons.check_circle_rounded, color: AppColors.success, size: 18),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 300 + index * 70), duration: 350.ms)
        .slideY(begin: 0.06, end: 0);
  }
}
