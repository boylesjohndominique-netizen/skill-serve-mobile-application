import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../marketplace/models/provider_model.dart';
import '../services/provider_service_service.dart';

/// Where customers send a GCash payment for this provider's jobs.
///
/// SkillServe is never in the payment path: a customer who chooses GCash pays
/// the provider's own number directly, so without these details the app can
/// only tell them to message the provider and arrange it. The provider then
/// owes SkillServe its commission out of what they received.
class GcashDetailsScreen extends StatefulWidget {
  const GcashDetailsScreen({super.key});

  @override
  State<GcashDetailsScreen> createState() => _GcashDetailsScreenState();
}

class _GcashDetailsScreenState extends State<GcashDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _name = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ProviderModel profile = await ProviderServiceService().getMyProfile();
      if (!mounted) return;
      setState(() {
        _number.text = profile.gcashNumber ?? '';
        _name.text = profile.gcashName ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e, 'Unable to load your payment details.');
        _loading = false;
      });
    }
  }

  /// Emptying both fields removes the details, which is how a provider stops
  /// advertising a number they no longer use. Emptying only one is a mistake,
  /// and the validators say so.
  bool get _isClearing => _number.text.trim().isEmpty && _name.text.trim().isEmpty;

  Future<void> _save() async {
    if (!_isClearing && !(_formKey.currentState?.validate() ?? false)) return;

    final clearing = _isClearing;
    setState(() => _saving = true);
    try {
      // Sent as typed; the API normalises the number and stores 11 digits.
      // Both columns are nullable, so null is what removes them.
      await ProviderServiceService().updateMyProfile({
        'gcash_number': clearing ? null : _number.text.trim(),
        'gcash_name': clearing ? null : _name.text.trim(),
      });
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.success(
        context,
        clearing
            ? 'Your GCash details are removed. Customers will be asked to message you instead.'
            : 'Your GCash details are saved.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, apiErrorMessage(e, 'Unable to save your payment details.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('GCash details')),
      body: SafeArea(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 80, count: 2),
              )
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSizes.pageHPad),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceAltDark : AppColors.infoBg,
                            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppIcon(AppIcons.info_outline_rounded,
                                  color: AppColors.info, size: AppSizes.iconMd),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Text(
                                  'Customers who choose GCash pay you directly on this number. '
                                  'SkillServe never holds the money, so keep these details '
                                  'correct — and remember the commission stays owed out of '
                                  'what you receive.',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        AppTextField(
                          label: 'GCash number',
                          hint: '09XX XXX XXXX',
                          controller: _number,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setState(() {}),
                          // The API normalises +63 / 63 / 9XXXXXXXXX to
                          // 09XXXXXXXXX itself, so this accepts the same
                          // shapes rather than refusing a number that is
                          // actually fine.
                          validator: (value) {
                            final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                            if (digits.isEmpty) {
                              return _isClearing
                                  ? null
                                  : 'Enter the GCash number customers should pay.';
                            }
                            final normalised = switch (digits) {
                              _ when digits.startsWith('639') && digits.length == 12 =>
                                '0${digits.substring(2)}',
                              _ when digits.startsWith('9') && digits.length == 10 => '0$digits',
                              _ => digits,
                            };
                            if (!RegExp(r'^09\d{9}$').hasMatch(normalised)) {
                              return 'Enter an 11-digit GCash number starting with 09.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.lg),
                        AppTextField(
                          label: 'Account name',
                          hint: 'The name GCash shows for this number',
                          controller: _name,
                          maxLength: 120,
                          onChanged: (_) => setState(() {}),
                          validator: (value) => (value ?? '').trim().isEmpty && !_isClearing
                              ? 'Enter the name on the GCash account.'
                              : null,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'Customers are asked to check this name matches before they send, '
                          'so it must be exactly what GCash displays.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        PrimaryButton(
                          label: _isClearing ? 'Remove details' : 'Save details',
                          isLoading: _saving,
                          onPressed: _saving ? null : _save,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
