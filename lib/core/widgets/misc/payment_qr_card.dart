import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/payment_qr.dart';
import '../buttons/primary_button.dart';
import '../feedback/app_snackbar.dart';

/// A payment QR code with the exact amount it is for, and a button to save it
/// to the gallery for GCash's "Upload QR".
///
/// Give it either [payload] (QR Ph text, drawn here — the provider's own QR
/// with the booking amount) or [image] (a ready-made QR image — PayMongo's).
class PaymentQrCard extends StatefulWidget {
  const PaymentQrCard({
    super.key,
    this.payload,
    this.image,
    required this.amount,
    required this.saveName,
    this.caption,
  }) : assert(payload != null || image != null);

  final String? payload;
  final Uint8List? image;

  /// The amount as the API formatted it, e.g. "200.00".
  final String amount;

  /// File name for the saved image, without extension.
  final String saveName;

  /// Who the money goes to, under the amount.
  final String? caption;

  @override
  State<PaymentQrCard> createState() => _PaymentQrCardState();
}

class _PaymentQrCardState extends State<PaymentQrCard> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final bytes = widget.image ?? await PaymentQr.png(widget.payload!);
    final saved = await PaymentQr.saveToGallery(bytes, widget.saveName);
    if (!mounted) return;
    setState(() => _saving = false);
    saved
        ? AppSnackbar.success(context, 'QR saved. In GCash, tap Pay QR → Upload QR and choose it.')
        : AppSnackbar.error(context, 'Could not save the QR. Allow access to Photos, or take a screenshot instead.');
  }

  @override
  Widget build(BuildContext context) {
    const qrSize = 220.0;

    return Column(
      children: [
        // White behind the code whatever the theme, so it always scans.
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: widget.image != null
              ? Image.memory(widget.image!, width: qrSize, height: qrSize, fit: BoxFit.contain, gaplessPlayback: true)
              : QrImageView(
                  data: widget.payload!,
                  version: QrVersions.auto,
                  size: qrSize,
                  backgroundColor: Colors.white,
                  semanticsLabel: 'Payment QR code for ₱${widget.amount}',
                ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text('₱${widget.amount}', style: AppTextStyles.displayMedium),
        if (widget.caption != null) ...[
          const SizedBox(height: 2),
          Text(widget.caption!, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
        const SizedBox(height: AppSizes.md),
        // Filled, so it stands out in light and dark: saving the QR is how a
        // payment on this same phone gets into GCash.
        PrimaryButton(
          label: 'Save QR to gallery',
          icon: AppIcons.download_rounded,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
