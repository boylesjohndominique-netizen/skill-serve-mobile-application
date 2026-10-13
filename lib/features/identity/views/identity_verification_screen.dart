import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../services/id_photo_quality.dart';
import '../services/national_id_camera.dart';
import '../services/national_id_parser.dart';
import '../services/national_id_reader.dart';
import '../../../core/theme/app_palette.dart';

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

  /// The side whose new photo is being checked, or null.
  String? _checking;

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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondaryColor),
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
                'Both sides are required. Lay the card flat in good, even light with no flash glare, and hold steady until the text is sharp. Photos are taken with the camera and sent as is — no filters or edits.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondaryColor),
              ),
              const SizedBox(height: 14),

              _CaptureTile(
                type: PendingIdentityDocument.frontType,
                title: 'Front of card',
                document: identity.captured[PendingIdentityDocument.frontType],
                checking: _checking == PendingIdentityDocument.frontType,
                onCapture: _checking != null ? null : () => _capture(PendingIdentityDocument.frontType),
                onRemove: () => identity.remove(PendingIdentityDocument.frontType),
              ),
              const SizedBox(height: 12),
              _CaptureTile(
                type: PendingIdentityDocument.backType,
                title: 'Back of card',
                document: identity.captured[PendingIdentityDocument.backType],
                checking: _checking == PendingIdentityDocument.backType,
                onCapture: _checking != null ? null : () => _capture(PendingIdentityDocument.backType),
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

  /// Photographs one side with the same no-filter scanner as sign-up (no
  /// gallery: an edited or filtered picture cannot be told from a real one),
  /// then checks it before keeping it.
  Future<void> _capture(String type) async {
    final identity = context.read<IdentityController>();

    String? path;
    try {
      path = await captureNationalIdPhoto();
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'The camera could not be opened.');
      return;
    }
    if (path == null || !mounted) return;

    final Uint8List bytes = await File(path).readAsBytes();
    if (!mounted) return;

    setState(() => _checking = type);
    final issue = await _review(path, bytes);
    if (!mounted) return;
    setState(() => _checking = null);
    if (issue != null) {
      AppSnackbar.error(context, issue.message);
      return;
    }

    final base = path.split(RegExp(r'[/\\]')).last;
    final error = identity.capture(
      PendingIdentityDocument(type: type, fileName: base.contains('.') ? base : '$base.jpg', bytes: bytes),
    );
    if (error != null && mounted) AppSnackbar.error(context, error);
  }

  /// The photo's problem, if any. A photo that measures as blurry passes when
  /// its text or QR code can still be read — then it is sharp enough.
  Future<IdPhotoIssue?> _review(String path, Uint8List bytes) async {
    final issue = await IdPhotoQuality.check(bytes);
    if (issue != IdPhotoIssue.blurry) return issue;

    final reader = MlKitNationalIdReader();
    try {
      final text = NationalIdParser.parseFront(await reader.readText(path));
      if (!text.isEmpty) return null;
      return (await reader.readQrCodes(path)).isEmpty ? issue : null;
    } catch (_) {
      return issue;
    } finally {
      await reader.close();
    }
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
                color: verified ? AppColors.primary : context.textSecondaryColor,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondaryColor),
              ),
              if (identity.verification?.idNumberLast4 != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Card ending ${identity.verification!.idNumberLast4}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondaryColor),
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
          style: TextStyle(color: value == null ? context.textSecondaryColor : null),
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
    this.checking = false,
  });

  final String type;
  final String title;
  final PendingIdentityDocument? document;
  final VoidCallback? onCapture;

  /// A new photo of this side is being checked.
  final bool checking;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final captured = document != null;

    return InkWell(
      onTap: onCapture,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        // A minimum, not a fixed height: on a narrow phone the title wraps
        // and the card grows instead of clipping it.
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: captured ? AppColors.primary : context.textSecondaryColor.withValues(alpha: 0.3),
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
                      color: context.textSecondaryColor.withValues(alpha: 0.08),
                      child: const AppIcon(AppIcons.add_photo_alternate_outlined),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    checking ? 'Checking the photo…' : (captured ? 'Tap to retake' : 'Tap to capture'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondaryColor),
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
