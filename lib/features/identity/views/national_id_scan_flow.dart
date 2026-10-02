import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../controllers/identity_controller.dart';
import '../models/identity_verification_model.dart';
import '../models/scanned_national_id.dart';
import '../services/national_id_parser.dart';
import '../services/national_id_reader.dart';

/// Takes a photo of the camera, or null when the user backs out.
typedef TakePhoto = Future<XFile?> Function();

/// Sign-up's first step: photograph the front of the National ID, then —
/// without being asked — the back, and read both on the phone.
///
/// The two photos are kept in [IdentityController] so they can be submitted
/// for review once the account exists; what was read is handed to
/// [onComplete] to fill the sign-up form, where the user confirms it.
class NationalIdScanFlow extends StatefulWidget {
  const NationalIdScanFlow({super.key, required this.onComplete, this.reader, this.takePhoto});

  final ValueChanged<ScannedNationalId> onComplete;
  final NationalIdReader? reader;
  final TakePhoto? takePhoto;

  @override
  State<NationalIdScanFlow> createState() => _NationalIdScanFlowState();
}

enum _Side { front, back }

class _NationalIdScanFlowState extends State<NationalIdScanFlow> {
  late final NationalIdReader _reader = widget.reader ?? MlKitNationalIdReader();
  _Side _side = _Side.front;
  bool _reading = false;
  ScannedNationalId _front = ScannedNationalId.empty;

  @override
  void dispose() {
    if (widget.reader == null) _reader.close();
    super.dispose();
  }

  Future<XFile?> _photo() => widget.takePhoto != null
      ? widget.takePhoto!()
      : ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2400);

  Future<void> _capture() async {
    final identity = context.read<IdentityController>();
    XFile? file;
    try {
      file = await _photo();
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'The camera could not be opened.');
      return;
    }
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final name = file.name.contains('.') ? file.name : '${file.name}.jpg';
    final error = identity.capture(PendingIdentityDocument(
      type: _side == _Side.front ? PendingIdentityDocument.frontType : PendingIdentityDocument.backType,
      fileName: name,
      bytes: bytes,
    ));
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }

    setState(() => _reading = true);
    try {
      if (_side == _Side.front) {
        _front = NationalIdParser.parseFront(await _reader.readText(file.path));
        if (!mounted) return;
        // Straight on to the back: the user never has to ask for it.
        setState(() {
          _side = _Side.back;
          _reading = false;
        });
        return;
      }

      // The QR code is machine-written, so what it says corrects what the
      // camera read off the front; the address is only on the front.
      var scanned = _front;
      for (final code in await _reader.readQrCodes(file.path)) {
        scanned = scanned.overriddenBy(NationalIdParser.parseQr(code));
      }
      if (!mounted) return;
      setState(() => _reading = false);

      if (scanned.isEmpty) {
        final retake = await _askToRetake();
        if (!mounted) return;
        if (retake) {
          setState(() => _side = _Side.front);
          return;
        }
      }
      identity.setScanned(scanned);
      widget.onComplete(scanned);
    } catch (_) {
      if (!mounted) return;
      setState(() => _reading = false);
      AppSnackbar.error(context, 'Your ID could not be read. Try again with the whole card in frame.');
    }
  }

  Future<bool> _askToRetake() async {
    final retake = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('We could not read your ID'),
        content: const Text(
          'Retake the photos in good light with the whole card in frame, or continue and type your details.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Type them instead')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Retake')),
        ],
      ),
    );
    return retake ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final front = _side == _Side.front;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Step ${front ? 1 : 2} of 2', style: theme.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          front ? 'Front of your National ID' : 'Now the back of your National ID',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          front
              ? 'Your PhilSys card or printed ePhilID. Your name, birthday and address are filled in from it.'
              : 'Turn the card over. Keep the QR code sharp and fully in frame.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 1.586, // an ID-1 card
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: _reading
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Reading your ID…')],
                    )
                  : Icon(front ? Icons.badge_outlined : Icons.qr_code_2_rounded, size: 72, color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _Tips(),
        const SizedBox(height: 20),
        PrimaryButton(
          label: front ? 'Take photo of the front' : 'Take photo of the back',
          isLoading: _reading,
          onPressed: _reading ? null : _capture,
        ),
        if (!front && !_reading)
          TextButton(
            onPressed: () => setState(() => _side = _Side.front),
            child: const Text('Retake the front'),
          ),
      ],
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) {
    const tips = ['Lay the card flat in good light', 'Fill the frame, no glare on the text', 'Only SkillServe reviewers see these photos'];
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(tip, style: style)),
            ]),
          ),
      ],
    );
  }
}
