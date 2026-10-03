import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../controllers/identity_controller.dart';
import '../models/identity_verification_model.dart';
import '../models/scanned_national_id.dart';
import '../services/national_id_camera.dart';
import '../services/national_id_parser.dart';
import '../services/national_id_reader.dart';
import '../../../core/theme/app_palette.dart';

/// Sign-up's first step: scan the front of the National ID, then — without
/// being asked — the back, and read both on the phone.
///
/// The camera is ML Kit's Document Scanner ([captureNationalIdPhoto]), which
/// finds and captures the card by itself. Reading never blocks: a side that
/// cannot be read is still kept, and only when nothing at all was read is the
/// user offered a retake or typing the details.
///
/// The two images are kept in [IdentityController] so they can be submitted
/// for review once the account exists; what was read is handed to
/// [onComplete] to fill the sign-up form, where the user confirms it.
class NationalIdScanFlow extends StatefulWidget {
  const NationalIdScanFlow({super.key, required this.onComplete, this.reader, this.capturePhoto, this.readFile});

  final ValueChanged<ScannedNationalId> onComplete;
  final NationalIdReader? reader;
  final CaptureIdPhoto? capturePhoto;

  /// Reads a captured image; the file system unless a test supplies bytes.
  final Future<Uint8List> Function(String path)? readFile;

  @override
  State<NationalIdScanFlow> createState() => _NationalIdScanFlowState();
}

enum _Side { front, back }

class _NationalIdScanFlowState extends State<NationalIdScanFlow> {
  late final NationalIdReader _reader = widget.reader ?? MlKitNationalIdReader();
  _Side _side = _Side.front;
  bool _reading = false;

  /// What the front said, and any QR printed on it (the paper ePhilID has
  /// its QR on the front).
  ScannedNationalId _front = ScannedNationalId.empty;
  List<String> _frontQr = const [];

  /// Why the last read failed, shown if nothing could be read so the user
  /// can report it.
  String? _lastError;

  @override
  void dispose() {
    if (widget.reader == null) _reader.close();
    super.dispose();
  }

  Future<void> _capture() async {
    final identity = context.read<IdentityController>();
    final side = _side;

    String? path;
    try {
      path = await (widget.capturePhoto ?? captureNationalIdPhoto)();
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'The camera could not be opened. (${_describe(e)})');
      return;
    }
    if (path == null || !mounted) return;

    final bytes = await (widget.readFile ?? (String p) => File(p).readAsBytes())(path);
    if (!mounted) return;
    final base = path.split(RegExp(r'[/\\]')).last;
    final error = identity.capture(PendingIdentityDocument(
      type: side == _Side.front ? PendingIdentityDocument.frontType : PendingIdentityDocument.backType,
      fileName: base.contains('.') ? base : '$base.jpg',
      bytes: bytes,
    ));
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }

    setState(() => _reading = true);
    var text = ScannedNationalId.empty;
    var qr = const <String>[];
    try {
      text = NationalIdParser.parseFront(await _reader.readText(path));
      qr = await _reader.readQrCodes(path);
    } catch (e, stack) {
      // A side that cannot be read is not the end: the image is kept and the
      // flow carries on.
      debugPrint('[NationalId] reading the ${side.name} failed: $e\n$stack');
      _lastError = _describe(e);
    }
    if (!mounted) return;

    if (side == _Side.front) {
      _front = text;
      _frontQr = qr;
      setState(() {
        _side = _Side.back;
        _reading = false;
      });
      _openBackScanner();
      return;
    }

    // The front's text outranks what is printed on the back; the QR code,
    // being machine-written, outranks both. The address is only on the front.
    var scanned = text.overriddenBy(_front);
    for (final code in [..._frontQr, ...qr]) {
      scanned = scanned.overriddenBy(NationalIdParser.parseQr(code));
    }
    setState(() => _reading = false);

    if (scanned.isEmpty) {
      final retake = await _askToRetake();
      if (!mounted) return;
      if (retake) {
        setState(() {
          _side = _Side.front;
          _lastError = null;
        });
        return;
      }
    }
    identity.setScanned(scanned);
    widget.onComplete(scanned);
  }

  /// Opens the scanner for the back by itself, a moment after the front is
  /// read, so the user only has to turn the card over.
  void _openBackScanner() {
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _side == _Side.back && !_reading) _capture();
    });
  }

  static String _describe(Object error) {
    final text = error is PlatformException ? '${error.code}: ${error.message ?? ''}' : '$error';
    return text.length > 140 ? '${text.substring(0, 140)}…' : text;
  }

  Future<bool> _askToRetake() async {
    final retake = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('We could not read your ID'),
        content: Text(
          'Retake them in good light, or continue and type your details.'
          '${_lastError == null ? '' : '\n\nDetails: $_lastError'}',
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
        Text('Step ${front ? 1 : 2} of 2', style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondaryColor)),
        const SizedBox(height: 4),
        Text(
          front ? 'Front of your National ID' : 'Now the back of your National ID',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          front
              ? 'Your PhilSys card or printed ePhilID. Hold it inside the frame — it is found and captured automatically. Your name, birthday and address are filled in from it.'
              : 'Turn the card over. The scanner opens by itself; keep the QR code in view.',
          style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondaryColor),
        ),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 1.586, // an ID-1 card
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.textSecondaryColor.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: _reading
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Reading your ID…')],
                    )
                  : Icon(front ? Icons.badge_outlined : Icons.qr_code_2_rounded, size: 72, color: context.textSecondaryColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _Tips(),
        const SizedBox(height: 20),
        PrimaryButton(
          label: front ? 'Scan the front' : 'Scan the back',
          isLoading: _reading,
          onPressed: _reading ? null : _capture,
        ),
        if (!front && !_reading)
          TextButton(
            onPressed: () => setState(() => _side = _Side.front),
            child: const Text('Scan the front again'),
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
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondaryColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              Icon(Icons.check_circle_outline_rounded, size: 16, color: context.textSecondaryColor),
              const SizedBox(width: 6),
              Expanded(child: Text(tip, style: style)),
            ]),
          ),
      ],
    );
  }
}
