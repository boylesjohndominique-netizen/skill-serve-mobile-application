import 'package:flutter/material.dart';
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
    final providerProfile = MockData.providers.firstWhere((p) => p.user.id == MockData.currentProvider.id, orElse: () => MockData.providers.first);

    final earningsThisMonth = MockData.bookingsForProvider
        .where((b) => b.status.name == 'completed')
        .fold<double>(0, (sum, b) => sum + b.amount);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => bookings.loadProviderBookings(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad, vertical: AppSizes.lg),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, ${user?.firstName ?? 'there'} 👋', style: AppTextStyles.headlineLarge),
                      Text('Here\'s your business at a glance', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/notifications'),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(999)),
                      child: const Icon(Icons.notifications_outlined, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              InkWell(
                onTap: () => context.push('/verification-status'),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
              ),

              const SizedBox(height: AppSizes.xl),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSizes.md,
                crossAxisSpacing: AppSizes.md,
                childAspectRatio: 1.5,
                children: [
                  _StatTile(label: 'Pending Requests', value: '${bookings.requests.length}', icon: Icons.pending_actions_rounded, onTap: () => context.push('/booking-requests')),
                  _StatTile(label: 'Active Jobs', value: '${bookings.active.length}', icon: Icons.work_rounded, onTap: () => context.push('/active-jobs')),
                  _StatTile(label: 'Completed', value: '${bookings.completed.length}', icon: Icons.task_alt_rounded, onTap: () => context.push('/completed-jobs')),
                  _StatTile(label: 'This Month', value: Formatters.peso(earningsThisMonth), icon: Icons.payments_rounded, onTap: () => context.push('/earnings')),
                ],
              ),

              const SizedBox(height: AppSizes.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Requests', style: AppTextStyles.headlineMedium),
                  TextButton(onPressed: () => context.push('/booking-requests'), child: const Text('See all')),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              if (bookings.isLoading)
                const ShimmerCardList(count: 2, itemHeight: 130)
              else if (bookings.requests.isEmpty)
                const EmptyState(icon: Icons.inbox_outlined, title: 'No new requests', message: 'New booking requests will show up here.')
              else
                Column(
                  children: [
                    for (final b in bookings.requests.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: BookingCard(booking: b, isProviderView: true, onTap: () => context.push('/booking-details/${b.id}')),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _StatTile({required this.label, required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.secondary, size: 20),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.titleLarge.copyWith(fontFamily: AppTextStyles.headlineLarge.fontFamily)),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
