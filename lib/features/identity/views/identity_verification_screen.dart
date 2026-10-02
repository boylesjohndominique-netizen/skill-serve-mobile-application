import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/identity_controller.dart';
import '../models/identity_verification_model.dart';

/// Capture the Philippine National ID, front and back, and send it for review.
///
/// Shown straight after sign-up: an account is asked for its ID before it
/// starts booking, rather than being stopped at the first transaction.
///
/// The card number is typed here, sent once, and never stored on the device —
/// the API returns only its last four digits afterwards.
class IdentityVerificationScreen extends StatefulWidget {
  /// Where to go once the holder is done here. Registration sends a provider
  /// on to their business onboarding; everyone else lands on their own home,
  /// which is what null means.
  final String? next;

  const IdentityVerificationScreen({super.key, this.next});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idNumber = TextEditingController();
  final _fullName = TextEditingController();
  DateTime? _birthdate;

  @override
  void initState() {
    super.initState();
    // Opened after sign-up when the scanned card could not be sent: start
    // from what was read and confirmed, not from blank fields.
    final scanned = context.read<IdentityController>().scanned;
    if (scanned != null) {
      _idNumber.text = scanned.formattedCardNumber ?? '';
      _fullName.text = scanned.fullName;
      _birthdate = scanned.birthdate;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IdentityController>().load();
    });
  }

  @override
  void dispose() {
    // The card number lives only as long as this form does.
    _idNumber.dispose();
    _fullName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identity = context.watch<IdentityController>();

    if (identity.isLoading && identity.verification == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Already submitted or approved: show where it stands instead of the form.
    if (identity.isPending || identity.isVerified) {
      return _StatusView(identity: identity, onContinue: _continue);
    }

    final rejection = identity.verification?.rejectionReason;

    return Scaffold(
      // A back arrow appears only when there is somewhere to go back to, so
      // the screen is dismissable when it was opened from Settings and is a
      // dead end straight after sign-up, where skipping is offered below
      // instead (when the platform allows it).
      appBar: AppBar(title: const Text('Verify your identity')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Philippine National ID',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'SkillServe verifies every account before it can book or take on work. '
                'Your ID is reviewed by our team and is never shown to other users.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              if (rejection != null) ...[
                const SizedBox(height: 16),
                _RejectionNotice(reason: rejection),
              ],
              const SizedBox(height: 24),

              AppTextField(
                label: 'PhilSys card number',
                hint: '1234-5678-9012-3456',
                controller: _idNumber,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.isEmpty) return 'Enter your National ID number.';
                  if (digits.length != 16) return 'The card number is 16 digits.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Full name',
                hint: 'Exactly as printed on the card',
                controller: _fullName,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter your name as printed on the card.' : null,
              ),
              const SizedBox(height: 16),

              _BirthdateField(
                value: _birthdate,
                onPick: (date) => setState(() => _birthdate = date),
              ),
              const SizedBox(height: 28),

              Text(
                'Photos of your card',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Both sides are required. Make sure the whole card is in frame and the text is readable.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              _CaptureTile(
                type: PendingIdentityDocument.frontType,
                title: 'Front of card',
                document: identity.captured[PendingIdentityDocument.frontType],
                onCapture: () => _capture(PendingIdentityDocument.frontType),
                onRemove: () => identity.remove(PendingIdentityDocument.frontType),
              ),
              const SizedBox(height: 12),
              _CaptureTile(
                type: PendingIdentityDocument.backType,
                title: 'Back of card',
                document: identity.captured[PendingIdentityDocument.backType],
                onCapture: () => _capture(PendingIdentityDocument.backType),
                onRemove: () => identity.remove(PendingIdentityDocument.backType),
              ),

              if (identity.isSubmitting) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(value: identity.progress == 0 ? null : identity.progress),
              ],

              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Submit for review',
                isLoading: identity.isSubmitting,
                onPressed: identity.canSubmit ? _submit : null,
              ),

              // Only offered when the platform does not yet require it of this
              // account — otherwise there is nothing useful behind the skip.
              if (!identity.isRequired) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: identity.isSubmitting ? null : _continue,
                  child: const Text("I'll do this later"),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capture(String type) async {
    final identity = context.read<IdentityController>();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const AppIcon(AppIcons.camera_alt_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const AppIcon(AppIcons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2400,
      );
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'The camera could not be opened.');
      return;
    }
    if (file == null || !mounted) return;

    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) return;

    final name = file.name.contains('.') ? file.name : '${file.name}.jpg';
    final error = identity.capture(
      PendingIdentityDocument(type: type, fileName: name, bytes: bytes),
    );
    if (error != null && mounted) AppSnackbar.error(context, error);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_birthdate == null) {
      AppSnackbar.error(context, 'Enter your date of birth.');
      return;
    }

    final identity = context.read<IdentityController>();
    final ok = await identity.submit(
      idNumber: _idNumber.text,
      fullName: _fullName.text,
      birthdate: _birthdate!,
    );
    if (!mounted) return;

    if (ok) {
      // Clear the number from memory the moment it has been sent.
      _idNumber.clear();
      AppSnackbar.success(context, 'National ID submitted. We will review it shortly.');
    } else {
      AppSnackbar.error(context, identity.errorMessage ?? 'Unable to submit your National ID.');
    }
  }

  void _continue() {
    final next = widget.next;
    if (next != null && next.isNotEmpty) {
      context.go(next);
      return;
    }
    final auth = context.read<AuthController>();
    context.go(auth.isProvider ? '/provider' : '/client');
  }
}

/// Shown once the card is with the reviewers, or approved.
class _StatusView extends StatelessWidget {
  const _StatusView({required this.identity, required this.onContinue});

  final IdentityController identity;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final verified = identity.isVerified;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your identity')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                verified ? AppIcons.verified_rounded : AppIcons.hourglass_top_rounded,
                size: 72,
                color: verified ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 20),
              Text(
                verified ? 'Identity verified' : 'Under review',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                verified
                    ? 'You are all set. You can book services and take on work.'
                    : 'We have your National ID and are checking it. This usually takes a short while — '
                        'we will let you know as soon as it is done.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              if (identity.verification?.idNumberLast4 != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Card ending ${identity.verification!.idNumberLast4}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 32),
              PrimaryButton(label: 'Continue', onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectionNotice extends StatelessWidget {
  const _RejectionNotice({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(AppIcons.info_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your last submission was not accepted',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(reason, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdateField extends StatelessWidget {
  const _BirthdateField({required this.value, required this.onPick});

  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? 'Select your date of birth'
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(now.year - 20),
          firstDate: DateTime(now.year - 120),
          // The card belongs to a person who already exists, so tomorrow is
          // never valid.
          lastDate: now,
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of birth',
          border: OutlineInputBorder(),
        ),
        child: Text(
          label,
          style: TextStyle(color: value == null ? AppColors.textSecondary : null),
        ),
      ),
    );
  }
}

/// One side of the card: capture it, preview it, replace it.
class _CaptureTile extends StatelessWidget {
  const _CaptureTile({
    required this.type,
    required this.title,
    required this.document,
    required this.onCapture,
    required this.onRemove,
  });

  final String type;
  final String title;
  final PendingIdentityDocument? document;
  final VoidCallback onCapture;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final captured = document != null;

    return InkWell(
      onTap: onCapture,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 96,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: captured ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: captured
                  ? Image.memory(document!.bytes, width: 110, height: 76, fit: BoxFit.cover)
                  : Container(
                      width: 110,
                      height: 76,
                      color: AppColors.textSecondary.withValues(alpha: 0.08),
                      child: const AppIcon(AppIcons.add_photo_alternate_outlined),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    captured ? 'Tap to retake' : 'Tap to capture',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (captured)
              IconButton(
                icon: const AppIcon(AppIcons.close_rounded),
                tooltip: 'Remove',
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
