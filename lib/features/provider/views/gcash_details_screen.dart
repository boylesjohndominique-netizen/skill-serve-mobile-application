import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/payment_qr.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/utils/ph_mobile_number.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../marketplace/models/provider_model.dart';
import '../services/provider_service_service.dart';
import '../../../core/widgets/feedback/app_notice.dart';

/// Where customers send a GCash payment for this provider's jobs.
///
/// SkillServe is never in the payment path: a customer who chooses GCash pays
/// the provider's own number directly, so without these details the app can
/// only tell them to message the provider and arrange it. The provider then
/// owes SkillServe its commission out of what they received.
///
/// The provider can also add their GCash "Receive via QR" code. The app reads
/// it on the phone and saves the code's text; each GCash booking then shows
/// the customer a copy with the exact amount in it.
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

  /// The saved GCash QR as its QR Ph text, or null.
  String? _qrPayload;
  bool _qrBusy = false;

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
        _number.text = PhMobileNumber.normalise(profile.gcashNumber ?? '');
        _name.text = profile.gcashName ?? '';
        _qrPayload = profile.gcashQrPayload;
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

  /// Reads the QR from a saved image on the phone and stores its text.
  Future<void> _uploadQr() async {
    if (_qrBusy) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() => _qrBusy = true);
    final payload = await PaymentQr.readFromImage(picked.path);
    if (!mounted) return;

    if (payload == null || !PaymentQr.looksLikeQrPh(payload)) {
      setState(() => _qrBusy = false);
      AppSnackbar.error(
        context,
        payload == null
            ? 'No QR code was found in that picture. Choose the QR you saved from GCash.'
            : 'That QR is not a GCash payment QR. In GCash, open Receive → Receive via QR and save that one.',
      );
      return;
    }

    await _storeQr(payload, 'Your GCash QR is saved. Customers now get it with the exact amount.');
  }

  Future<void> _removeQr() => _storeQr(null, 'Your GCash QR is removed.');

  Future<void> _storeQr(String? payload, String done) async {
    setState(() => _qrBusy = true);
    try {
      final profile = await ProviderServiceService().updateMyProfile({'gcash_qr_payload': payload});
      if (!mounted) return;
      setState(() {
        _qrPayload = profile.gcashQrPayload;
        _qrBusy = false;
      });
      AppSnackbar.success(context, done);
    } catch (e) {
      if (!mounted) return;
      setState(() => _qrBusy = false);
      AppSnackbar.error(context, apiErrorMessage(e, 'Unable to save your GCash QR.'));
    }
  }

  @override
  Widget build(BuildContext context) {

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
                        const AppNotice(
                          message: 'Customers who choose GCash pay you directly on this number. '
                              'SkillServe never holds the money, so keep these details '
                              'correct — and remember the commission stays owed out of '
                              'what you receive.',
                        ),
                        const SizedBox(height: AppSizes.xl),
                        AppTextField(
                          label: 'GCash number',
                          hint: PhMobileNumber.hint,
                          controller: _number,
                          keyboardType: TextInputType.phone,
                          // Only an 11-digit 09 number can be typed; a pasted
                          // +63 number is turned into one. The counter shows
                          // how many of the 11 digits are in.
                          inputFormatters: [PhMobileNumber.formatter],
                          maxLength: PhMobileNumber.length,
                          onChanged: (_) => setState(() {}),
                          validator: (value) => PhMobileNumber.validate(
                            value,
                            required: !_isClearing,
                            requiredMessage: 'Enter the GCash number customers should pay.',
                          ),
                        ),
                        Text(
                          'Philippine mobile number only. A +63 number is changed to 09 '
                          'automatically.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSizes.lg),
                        AppTextField(
                          label: 'Account name',
                          hint: 'e.g. Juan Dela Cruz',
                          controller: _name,
                          maxLength: 120,
                          onChanged: (_) => setState(() {}),
                          validator: (value) => (value ?? '').trim().isEmpty && !_isClearing
                              ? 'Enter the name on the GCash account.'
                              : null,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'Your name as registered on this GCash account — check it in GCash under '
                          'Profile. When a customer enters your number, GCash shows a partly '
                          'hidden version of this name (like JU** D***), and the app tells them '
                          'to send only if it matches, so they know they are paying you.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        PrimaryButton(
                          label: _isClearing ? 'Remove details' : 'Save details',
                          isLoading: _saving,
                          onPressed: _saving ? null : _save,
                        ),

                        // ── The GCash QR ──
                        const SizedBox(height: AppSizes.xxl),
                        Text('Your GCash QR', style: AppTextStyles.titleLarge),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'Add your GCash QR and each customer paying by GCash gets a QR with the '
                          'exact amount of their booking, paid straight to you. In GCash, open '
                          'Receive → Receive via QR, save the QR to your gallery, then upload it here.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSizes.md),
                        if (_qrPayload != null) ...[
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(AppSizes.sm),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                              ),
                              child: QrImageView(
                                data: _qrPayload!,
                                version: QrVersions.auto,
                                size: 160,
                                backgroundColor: Colors.white,
                                semanticsLabel: 'Your saved GCash QR',
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                        ],
                        OutlinedAppButton(
                          label: _qrBusy
                              ? 'Saving…'
                              : _qrPayload == null
                                  ? 'Upload my GCash QR'
                                  : 'Replace my GCash QR',
                          onPressed: _qrBusy ? null : _uploadQr,
                        ),
                        if (_qrPayload != null)
                          TextButton(
                            onPressed: _qrBusy ? null : _removeQr,
                            child: const Text('Remove QR'),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
