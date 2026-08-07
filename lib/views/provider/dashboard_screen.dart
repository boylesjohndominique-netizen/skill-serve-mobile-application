import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/provider_booking_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/cards/booking_card.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../core/widgets/misc/stat_card.dart';
import '../../data/mock/mock_data.dart';
import '../../models/booking_model.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, ${user?.firstName ?? 'there'} 👋', style: AppTextStyles.headlineLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Here\'s your business at a glance', style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
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
                      child: const AppIcon(AppIcons.notifications_outlined, size: 20),
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
                      AppIcon(
                        providerProfile.isVerified ? AppIcons.verified_rounded : AppIcons.hourglass_top_rounded,
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

              // ── Quick actions ──
              Row(
                children: [
                  _QuickAction(icon: AppIcons.add_circle_outline_rounded, label: 'Add service', onTap: () => context.push('/add-service'), index: 0),
                  const SizedBox(width: AppSizes.sm),
                  _QuickAction(icon: AppIcons.photo_library_outlined, label: 'Upload portfolio', onTap: () => context.push('/upload-portfolio'), index: 1),
                  const SizedBox(width: AppSizes.sm),
                  _QuickAction(icon: AppIcons.verified_user_outlined, label: 'Verification', onTap: () => context.push('/verification-status'), index: 2),
                ],
              ),

              const SizedBox(height: AppSizes.xl),

              // ── Stat tiles ──
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSizes.md,
                crossAxisSpacing: AppSizes.md,
                childAspectRatio: 1.35,
                children: [
                  StatCard(label: 'Pending Requests', value: '${bookings.requests.length}', icon: AppIcons.pending_actions_rounded, onTap: () => context.push('/booking-requests'))
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 350.ms)
                      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                  StatCard(label: 'Active Jobs', value: '${bookings.active.length}', icon: AppIcons.work_rounded, onTap: () => context.push('/active-jobs'))
                      .animate()
                      .fadeIn(delay: 330.ms, duration: 350.ms)
                      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                  StatCard(label: 'Completed', value: '${bookings.completed.length}', icon: AppIcons.task_alt_rounded, onTap: () => context.push('/completed-jobs'))
                      .animate()
                      .fadeIn(delay: 410.ms, duration: 350.ms)
                      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                  StatCard(label: 'This Month', value: Formatters.peso(earningsThisMonth), icon: AppIcons.payments_rounded, onTap: () => context.push('/earnings'))
                      .animate()
                      .fadeIn(delay: 490.ms, duration: 350.ms)
                      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                ],
              ),

              // ── Upcoming bookings ──
              const SizedBox(height: AppSizes.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Upcoming Bookings',
                      style: AppTextStyles.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  TextButton(onPressed: () => context.push('/booking-requests'), child: const Text('See all')),
                ],
              ).animate().fadeIn(delay: 420.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.md),
              if (bookings.isLoading)
                const ShimmerCardList(count: 2, itemHeight: 110)
              else if (bookings.active.isEmpty)
                const EmptyState(icon: AppIcons.event_available_outlined, title: 'Nothing scheduled', message: 'Confirmed jobs will show up here.')
              else
                Column(
                  children: [
                    for (var i = 0; i < bookings.active.take(2).length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: _UpcomingTile(booking: bookings.active[i], onTap: () => context.push('/booking-details/${bookings.active[i].id}')),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 460 + i * 60), duration: 350.ms)
                          .slideY(begin: 0.06, end: 0),
                  ],
                ),

              const SizedBox(height: AppSizes.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'New Requests',
                      style: AppTextStyles.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  TextButton(onPressed: () => context.push('/booking-requests'), child: const Text('See all')),
                ],
              ).animate().fadeIn(delay: 520.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.md),
              if (bookings.isLoading)
                const ShimmerCardList(count: 2, itemHeight: 130)
              else if (bookings.requests.isEmpty)
                const EmptyState(icon: AppIcons.inbox_outlined, title: 'No new requests', message: 'New booking requests will show up here.')
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

/// Compact quick-action tile for the dashboard.
class _QuickAction extends StatelessWidget {
  final AppIconData icon;
  final String label;
  final VoidCallback onTap;
  final int index;

  const _QuickAction({required this.icon, required this.label, required this.onTap, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
            boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: 22, color: AppColors.secondary),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 180 + index * 70), duration: 350.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }
}

/// Upcoming (confirmed / in-progress) booking row for the dashboard.
class _UpcomingTile extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _UpcomingTile({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: AppColors.brassGradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const AppIcon(AppIcons.event_available_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.serviceTitle, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${booking.clientName} · ${Formatters.dateShort(booking.bookingDate)} · ${booking.schedule}', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            StatusBadge.fromStatus(booking.status.name),
          ],
        ),
      ),
    );
  }
}
