import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../settings/models/platform_info.dart';
import '../../settings/services/platform_service.dart';
import '../models/commission_model.dart';
import '../services/commission_service.dart';

/// What the provider owes SkillServe, and what it stops them doing.
///
/// The commission is part of the price the provider advertises, so on every
/// job the customer pays the provider in full and the platform's share stays
/// with the provider until they remit it. While anything is outstanding they
/// cannot accept or start jobs or publish services — declining and cancelling
/// stay open so an existing queue can still be cleared.
///
/// There is nothing to pay here: SkillServe never handles the money, so a
/// remittance is arranged with support and recorded by an administrator.
class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  CommissionSummary? _summary;
  PlatformInfo? _platform;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await CommissionService().getSummary();
      // Where to send the remittance is platform information, and a failure to
      // read it must not hide what is owed.
      PlatformInfo? platform;
      try {
        platform = await PlatformService().get();
      } catch (_) {
        platform = null;
      }
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _platform = platform;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e, 'Unable to load your commission balance.');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Commission')),
      body: SafeArea(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 90),
              )
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: summary == null || !summary.hasOutstanding
                        ? ListView(
                            padding: const EdgeInsets.all(AppSizes.pageHPad),
                            children: const [
                              SizedBox(height: AppSizes.xxl),
                              EmptyState(
                                icon: AppIcons.task_alt_rounded,
                                title: 'Nothing outstanding',
                                message:
                                    'You have remitted every commission so far. New work is unaffected.',
                              ),
                            ],
                          )
                        : _content(context, summary),
                  ),
      ),
    );
  }

  Widget _content(BuildContext context, CommissionSummary summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supportEmail = _platform?.supportEmail ?? '';

    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageHPad),
      children: [
        // ── What is owed ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Outstanding commission',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textOnDark)),
              const SizedBox(height: AppSizes.xs),
              Text(
                '₱${summary.outstandingTotal}',
                style: AppTextStyles.displayMedium.copyWith(color: AppColors.textOnDark),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                'Across ${summary.outstandingCount} '
                '${summary.outstandingCount == 1 ? 'booking' : 'bookings'}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textOnDark),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),

        if (summary.isBlockedByCommission) ...[
          const SizedBox(height: AppSizes.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceAltDark : AppColors.errorBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIcon(AppIcons.block_rounded,
                    color: AppColors.error, size: AppSizes.iconMd),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    'New work is paused: you cannot accept or start jobs, or publish services, '
                    'until this is settled. Jobs you have already agreed to are unaffected — '
                    'you can still decline and cancel.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── How to settle it ──
        const SizedBox(height: AppSizes.lg),
        Text('How to settle', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSizes.xs),
        Text(
          'SkillServe never holds your money: the customer pays you the full advertised price, '
          'and the platform\'s share stays with you until you send it back. Arrange the '
          'remittance with support and an administrator records it against these bookings.'
          '${supportEmail.isEmpty ? '' : ' You can also email $supportEmail.'}',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSizes.md),
        OutlinedButton(
          onPressed: () => context.push('/support/new'),
          child: const Text('Contact support'),
        ),

        // ── The bookings behind the balance ──
        const SizedBox(height: AppSizes.xl),
        Text('Bookings', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSizes.md),
        for (final item in summary.outstanding)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: _CommissionRow(item: item, isDark: isDark),
          ),
      ],
    );
  }
}

class _CommissionRow extends StatelessWidget {
  const _CommissionRow({required this.item, required this.isDark});

  final OutstandingCommission item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
            color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6),
            width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.serviceTitle, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(
                  item.bookingNumber.isEmpty ? '—' : item.bookingNumber,
                  style: AppTextStyles.bodySmall,
                ),
                if (item.paidAt != null)
                  Text(
                    'Paid ${Formatters.dateShort(item.paidAt!)}',
                    style: AppTextStyles.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱${item.commissionAmount}', style: AppTextStyles.titleMedium),
              Text(
                '${item.commissionRate}% of ₱${item.totalPrice}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
