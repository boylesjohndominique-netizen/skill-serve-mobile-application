import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/info_row.dart';
import '../models/commission_model.dart';
import '../services/commission_service.dart';

/// "I've paid": the provider sends SkillServe's GCash what they owe, outside
/// the app, then submits the GCash reference number here.
///
/// Submitting settles nothing by itself — anyone can type a number — so new
/// work stays paused until an administrator finds the reference in
/// SkillServe's GCash history and confirms it. Pops `true` once submitted.
class PayCommissionScreen extends StatefulWidget {
  const PayCommissionScreen({super.key});

  @override
  State<PayCommissionScreen> createState() => _PayCommissionScreenState();
}

class _PayCommissionScreenState extends State<PayCommissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  final _amount = TextEditingController();

  CommissionSummary? _summary;
  bool _loading = true;
  String? _error;
  XFile? _receipt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _reference.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await CommissionService().getSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _amount.text = summary.outstandingTotal;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e, 'Unable to load what you owe.');
        _loading = false;
      });
    }
  }

  Future<void> _pickReceipt() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _receipt = file);
  }

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) AppSnackbar.success(context, '$what copied.');
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      await CommissionService().submitRemittance(
        reference: _reference.text.trim(),
        amountSent: _amount.text.trim(),
        proofPath: _receipt?.path,
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Payment submitted. SkillServe will confirm it once the money arrives.');
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackbar.error(context, apiErrorMessage(e, 'We could not submit your payment.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay commission')),
      body: SafeArea(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 90),
              )
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _content(context, _summary!),
      ),
    );
  }

  Widget _content(BuildContext context, CommissionSummary summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final account = summary.paymentAccount;

    if (!summary.hasOutstanding || summary.hasPendingRemittance || !account.configured) {
      return _Blocked(summary: summary);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pageHPad),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Step 1: send the money ──
            Text('1. Send it by GCash', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Open GCash and send the full amount to SkillServe. Check that GCash shows the account '
              'name below before you confirm the transfer.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSizes.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line, width: 0.8),
              ),
              child: Column(
                children: [
                  InfoRow(
                    icon: AppIcons.account_balance_wallet_rounded,
                    label: 'GCash number',
                    value: account.gcashNumber,
                    mono: true,
                  ),
                  InfoRow(
                    icon: AppIcons.person_outline_rounded,
                    label: 'Account name',
                    value: account.gcashAccountName,
                  ),
                  InfoRow(
                    icon: AppIcons.payments_outlined,
                    label: 'Amount',
                    value: '₱${summary.outstandingTotal}',
                    emphasize: true,
                  ),
                  if (account.paymentInstructions.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.sm),
                    Text(account.paymentInstructions, style: AppTextStyles.bodySmall),
                  ],
                  const SizedBox(height: AppSizes.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedAppButton(
                          label: 'Copy number',
                          onPressed: () => _copy(account.gcashNumber, 'GCash number'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: OutlinedAppButton(
                          label: 'Copy amount',
                          onPressed: () => _copy(summary.outstandingTotal, 'Amount'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),

            // ── Step 2: tell SkillServe ──
            const SizedBox(height: AppSizes.xl),
            Text('2. Enter the reference number', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.xs),
            Text(
              'GCash shows a reference number ("Ref No.") on the receipt once the transfer goes through.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSizes.md),
            AppTextField(
              label: 'GCash reference number',
              hint: 'e.g. 1012 345 678901',
              controller: _reference,
              keyboardType: TextInputType.number,
              maxLength: 40,
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
                if (digits.isEmpty) return 'Enter the reference number from your GCash receipt.';
                if (!RegExp(r'^[A-Za-z0-9]{6,40}$').hasMatch(digits)) {
                  return 'Enter the reference number exactly as it appears on your receipt.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),
            AppTextField(
              label: 'Amount sent (₱)',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              validator: (value) {
                final sent = double.tryParse((value ?? '').trim());
                final owed = double.tryParse(summary.outstandingTotal) ?? 0;
                if (sent == null || sent <= 0) return 'Enter the amount you sent.';
                if (sent < owed) return 'You owe ₱${summary.outstandingTotal}. Send the full amount first.';
                return null;
              },
            ),

            // ── Optional receipt ──
            const SizedBox(height: AppSizes.md),
            Text('Receipt screenshot (optional)', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSizes.xs),
            Text('Helps SkillServe find your payment faster.', style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSizes.sm),
            InkWell(
              onTap: _pickReceipt,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: _receipt != null ? context.accentInk : (isDark ? AppColors.lineDark : AppColors.line),
                    width: _receipt != null ? 2 : 1,
                  ),
                ),
                child: _receipt == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(AppIcons.add_photo_alternate_outlined, size: 32, color: context.textMutedColor),
                          const SizedBox(height: 8),
                          Text('Tap to attach the receipt', style: AppTextStyles.bodyMedium),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg - 1),
                        child: Image.file(File(_receipt!.path), fit: BoxFit.cover, width: double.infinity, height: 160),
                      ),
              ),
            ),
            if (_receipt != null)
              TextButton(
                onPressed: () => setState(() => _receipt = null),
                child: const Text('Remove receipt'),
              ),

            const SizedBox(height: AppSizes.lg),
            Text(
              'New work stays paused until SkillServe confirms the payment. You will get a notification '
              'either way.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSizes.md),
            PrimaryButton(label: "I've paid — submit", isLoading: _submitting, onPressed: _submit),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of the form when it cannot be used: nothing is owed, a
/// payment is already waiting, or SkillServe has not set up its GCash.
class _Blocked extends StatelessWidget {
  const _Blocked({required this.summary});

  final CommissionSummary summary;

  @override
  Widget build(BuildContext context) {
    final message = !summary.hasOutstanding
        ? 'You have nothing to pay right now.'
        : summary.hasPendingRemittance
            ? (summary.latestRemittance!.isQr
                ? 'You have a QR code open for this payment. Pay it, or wait until it expires.'
                : 'Your last payment is still waiting for SkillServe to confirm it.')
            : 'SkillServe has not set up its GCash details yet. Contact support to arrange your payment.';

    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageHPad),
      children: [
        const SizedBox(height: AppSizes.xxl),
        AppIcon(AppIcons.info_outline_rounded, size: 40, color: context.textMutedColor),
        const SizedBox(height: AppSizes.md),
        Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSizes.lg),
        if (summary.hasOutstanding && !summary.hasPendingRemittance)
          OutlinedAppButton(label: 'Contact support', onPressed: () => context.push('/support/new')),
      ],
    );
  }
}
