import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/provider_booking_controller.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/cards/booking_card.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../data/mock/mock_data.dart';

/// Provider's home tab — quick stats, verification status, and today's
/// pending requests.
class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderBookingController>().loadProviderBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final bookings = context.watch<ProviderBookingController>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final providerProfile = MockData.providers.firstWhere((p) => p.user.id == MockData.currentProvider.id, orElse: () => MockData.providers.first);

    final earningsThisMonth = MockData.bookingsForProvider
        .where((b) => b.status.name == 'completed')
        .fold<double>(0, (sum, b) => sum + b.amount);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () => bookings.loadProviderBookings(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad, vertical: AppSizes.lg),
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, ${user?.firstName ?? 'there'} 👋', style: AppTextStyles.headlineLarge),
                      Text('Here\'s your business at a glance', style: AppTextStyles.bodyMedium),
                    ],
                  ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.06, end: 0),
                  InkWell(
                    onTap: () => context.push('/notifications'),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.notifications_outlined, size: 20),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms).scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              // ── Verification banner ──
              InkWell(
                onTap: () => context.push('/verification-status'),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        providerProfile.isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          providerProfile.isVerified ? 'Your account is verified' : 'Verification in progress',
                          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      StatusBadge.fromStatus(providerProfile.verificationStatus),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),

              const SizedBox(height: AppSizes.xl),

              // ── Stat tiles ──
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSizes.md,
                crossAxisSpacing: AppSizes.md,
                childAspectRatio: 1.5,
                children: [
                  _StatTile(label: 'Pending Requests', value: '${bookings.requests.length}', icon: Icons.pending_actions_rounded, index: 0, onTap: () => context.push('/booking-requests')),
                  _StatTile(label: 'Active Jobs', value: '${bookings.active.length}', icon: Icons.work_rounded, index: 1, onTap: () => context.push('/active-jobs')),
                  _StatTile(label: 'Completed', value: '${bookings.completed.length}', icon: Icons.task_alt_rounded, index: 2, onTap: () => context.push('/completed-jobs')),
                  _StatTile(label: 'This Month', value: Formatters.peso(earningsThisMonth), icon: Icons.payments_rounded, index: 3, onTap: () => context.push('/earnings')),
                ],
              ),

              const SizedBox(height: AppSizes.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Requests', style: AppTextStyles.headlineMedium),
                  TextButton(onPressed: () => context.push('/booking-requests'), child: const Text('See all')),
                ],
              ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.md),
              if (bookings.isLoading)
                const ShimmerCardList(count: 2, itemHeight: 130)
              else if (bookings.requests.isEmpty)
                const EmptyState(icon: Icons.inbox_outlined, title: 'No new requests', message: 'New booking requests will show up here.')
              else
                Column(
                  children: [
                    for (var i = 0; i < bookings.requests.take(3).length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: BookingCard(booking: bookings.requests[i], isProviderView: true, onTap: () => context.push('/booking-details/${bookings.requests[i].id}')),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 550 + i * 60), duration: 350.ms)
                          .slideY(begin: 0.06, end: 0),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final int index;
  final VoidCallback onTap;

  const _StatTile({required this.label, required this.value, required this.icon, required this.index, required this.onTap});

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppAnimations.cardPressScale : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
            boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: AppColors.secondary, size: 20),
              const SizedBox(height: 8),
              Text(widget.value, style: AppTextStyles.titleLarge.copyWith(fontFamily: AppTextStyles.headlineLarge.fontFamily)),
              Text(widget.label, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 250 + widget.index * 80), duration: 350.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }
}
