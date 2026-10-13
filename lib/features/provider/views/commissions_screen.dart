import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../settings/models/platform_info.dart';
import '../../settings/services/platform_service.dart';
import '../controllers/commission_controller.dart';
import '../models/commission_model.dart';
import '../../../core/widgets/feedback/app_notice.dart';

/// What the provider owes SkillServe, and what it stops them doing.
///
/// The commission is part of the price the provider advertises, so on every
/// job the customer pays the provider in full and the platform's share stays
/// with the provider until they remit it. While anything is outstanding they
/// cannot accept or start jobs or publish services — declining and cancelling
/// stay open so an existing queue can still be cleared.
///
/// It is paid only by a PayMongo QR Ph code for the exact amount ("Pay with QR
/// code"), which PayMongo confirms. A QR code still open is offered again; a
/// GCash-reference payment made with an older app version, still waiting for
/// SkillServe or rejected, is shown here too.
class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  PlatformInfo? _platform;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final commissions = context.read<CommissionController>();
    // Where to send the remittance is platform information, and a failure to
    // read it must not hide what is owed.
    final platform = PlatformService().get().then<PlatformInfo?>((info) => info).catchError((_) => null);
    await commissions.load();
    final info = await platform;
    if (!mounted) return;
    setState(() => _platform = info);
  }

  @override
  Widget build(BuildContext context) {
    // Watched, so a confirmed or rejected GCash payment (reloaded by the
    // notification poller) shows here without a pull to refresh.
    final commissions = context.watch<CommissionController>();
    final summary = commissions.summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Commission')),
      body: SafeArea(
        // A reload in the background keeps the balance on screen.
        child: commissions.isLoading && summary == null
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 90),
              )
            : commissions.errorMessage != null && summary == null
                ? ErrorState(message: commissions.errorMessage!, onRetry: _load)
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
          const AppNotice(
            tone: NoticeTone.error,
            icon: AppIcons.block_rounded,
            message: 'New work is paused: you cannot accept new bookings, start a service or publish services '
                'until this is settled. Bookings you have already accepted are unaffected — '
                'you can still decline and cancel.',
          ),
        ],

        // Owed, not blocking yet, but it will: say when, so it can be paid in time.
        if (summary.warnsBeforeBlock) ...[
          const SizedBox(height: AppSizes.lg),
          _BlockWarning(summary: summary),
        ],

        // ── How to settle it ──
        const SizedBox(height: AppSizes.lg),
        Text('How to settle', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSizes.xs),
        ..._settle(context, summary, isDark, supportEmail),

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

  /// What the provider can do about the balance right now.
  /// Opens a payment screen, and reloads on return: a QR code opened there
  /// and left unpaid is still worth showing here.
  Future<void> _open(String route) async {
    await context.push<bool>(route);
    if (mounted) _load();
  }

  /// What the provider can do about the balance right now.
  List<Widget> _settle(BuildContext context, CommissionSummary summary, bool isDark, String supportEmail) {
    final latest = summary.latestRemittance;
    final account = summary.paymentAccount;

    if (latest != null && latest.isPending) {
      // A QR code still open: send them back to it rather than making another.
      if (latest.isQr) {
        return [
          _Notice(
            isDark: isDark,
            icon: AppIcons.qr_code_rounded,
            tone: NoticeTone.warning,
            text: 'You have a QR code open for ₱${latest.amountDue}. Scan it to pay — it is confirmed '
                'automatically.',
          ),
          const SizedBox(height: AppSizes.md),
          PrimaryButton(label: 'Show QR code', onPressed: () => _open('/commissions/qr')),
        ];
      }

      return [
        _Notice(
          isDark: isDark,
          icon: AppIcons.hourglass_top_rounded,
          tone: NoticeTone.warning,
          text: 'Your ₱${latest.amountSent} GCash payment (ref. ${latest.reference}) is waiting for '
              'SkillServe to confirm it. New work resumes as soon as it is confirmed — you will get a '
              'notification.',
        ),
      ];
    }

    return [
      if (latest != null && latest.isRejected) ...[
        _Notice(
          isDark: isDark,
          icon: AppIcons.info_outline_rounded,
          tone: NoticeTone.error,
          text: 'Your last payment (ref. ${latest.reference}) was not confirmed'
              '${(latest.rejectionReason ?? '').isEmpty ? '.' : ': ${latest.rejectionReason}'}',
        ),
        const SizedBox(height: AppSizes.md),
      ],
      // The commission is paid only by QR code, for the exact amount.
      Text(
        account.qrPaymentsAvailable
            ? 'Pay ₱${summary.outstandingTotal} with a QR code from GCash, Maya or your bank app. It is '
                'confirmed automatically, and new work resumes right away.'
            : 'Paying by QR code is not available right now. Contact support to settle your commission.'
                '${supportEmail.isEmpty ? '' : ' You can also email $supportEmail.'}',
        style: AppTextStyles.bodyMedium,
      ),
      const SizedBox(height: AppSizes.md),
      if (account.qrPaymentsAvailable) ...[
        PrimaryButton(label: 'Pay with QR code', onPressed: () => _open('/commissions/qr')),
        const SizedBox(height: AppSizes.sm),
      ],
      OutlinedButton(
        onPressed: () => context.push('/support/new'),
        child: const Text('Contact support'),
      ),
    ];
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.isDark,
    required this.icon,
    required this.tone,
    required this.text,
  });

  final bool isDark;
  final AppIconData icon;
  final NoticeTone tone;
  final String text;

  @override
  Widget build(BuildContext context) => AppNotice(tone: tone, icon: icon, message: text);
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

/// When unpaid commission will pause new work, while it has not yet.
class _BlockWarning extends StatelessWidget {
  final CommissionSummary summary;
  const _BlockWarning({required this.summary});

  @override
  Widget build(BuildContext context) {
    final deadline = summary.blockDeadline;
    final rules = [
      if (deadline != null) 'on ${Formatters.dateTime(deadline)}',
      if (summary.hasBlockThreshold) 'once it reaches ₱${summary.blockThreshold}',
    ];

    return AppNotice(
      tone: NoticeTone.warning,
      icon: AppIcons.schedule_rounded,
      message: 'Pay it in time to keep taking work: new bookings and services pause '
          '${rules.join(', or ')}, whichever comes first.',
    );
  }
}
