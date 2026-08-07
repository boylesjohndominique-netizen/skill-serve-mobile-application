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
                childAspectRatio: 1.5,
                children: [
                  _StatTile(label: 'Pending Requests', value: '${bookings.requests.length}', icon: AppIcons.pending_actions_rounded, index: 0, onTap: () => context.push('/booking-requests')),
                  _StatTile(label: 'Active Jobs', value: '${bookings.active.length}', icon: AppIcons.work_rounded, index: 1, onTap: () => context.push('/active-jobs')),
                  _StatTile(label: 'Completed', value: '${bookings.completed.length}', icon: AppIcons.task_alt_rounded, index: 2, onTap: () => context.push('/completed-jobs')),
                  _StatTile(label: 'This Month', value: Formatters.peso(earningsThisMonth), icon: AppIcons.payments_rounded, index: 3, onTap: () => context.push('/earnings')),
                ],
              ),

              // ── Upcoming bookings ──
              const SizedBox(height: AppSizes.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming Bookings', style: AppTextStyles.headlineMedium),
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
                  Text('New Requests', style: AppTextStyles.headlineMedium),
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

class _StatTile extends StatefulWidget {
  final String label;
  final String value;
  final AppIconData icon;
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
              AppIcon(widget.icon, color: AppColors.secondary, size: 20),
              const SizedBox(height: 8),
              Text(widget.value, style: AppTextStyles.titleLarge.copyWith(fontFamily: AppTextStyles.headlineLarge.fontFamily)),
              Text(widget.label, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    )                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 250 + widget.index * 80), duration: 350.ms)
                  .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
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
            children: [
              AppIcon(icon, size: 22, color: AppColors.secondary),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
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
              child: const AppIcon(AppIcons.event_available_rounded, color: Colors.white, size: 18),
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
