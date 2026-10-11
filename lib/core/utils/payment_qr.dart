import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Payment QR codes: reading a provider's own GCash QR from a saved image,
/// drawing one from its QR Ph text, and saving one to the gallery so it can
/// be opened in GCash's "Upload QR" — a QR shown on the phone that has to
/// scan it cannot be scanned any other way.
abstract final class PaymentQr {
  /// The text inside the first QR code in the image at [path], or null.
  /// Read on the phone, so the image itself never leaves it.
  static Future<String?> readFromImage(String path) async {
    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final codes = await scanner.processImage(InputImage.fromFilePath(path));
      for (final code in codes) {
        final value = code.rawValue?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    } finally {
      await scanner.close();
    }
  }

  /// Whether [payload] looks like a QR Ph payment code. The API checks it
  /// properly; this only catches a photo of the wrong QR before uploading.
  static bool looksLikeQrPh(String payload) => payload.startsWith('000201') && payload.contains('6304');

  /// The image bytes of a base-64 image as PayMongo returns it, with or
  /// without a `data:` prefix; null when it does not decode.
  static Uint8List? decodeImage(String value) {
    final comma = value.indexOf(',');
    final encoded = value.startsWith('data:') && comma >= 0 ? value.substring(comma + 1) : value;
    try {
      return base64Decode(encoded.trim());
    } catch (_) {
      return null;
    }
  }

  /// [data] as a black-on-white PNG with a quiet zone, so it scans when
  /// uploaded to GCash from the gallery.
  static Future<Uint8List> png(String data, {double size = 720}) async {
    const padding = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(Rect.fromLTWH(0, 0, size, size), Paint()..color = Colors.white)
      ..translate(padding, padding);

    QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
    ).paint(canvas, Size(size - padding * 2, size - padding * 2));

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  /// Saves [png] to the gallery; false when the permission was refused or
  /// saving failed.
  static Future<bool> saveToGallery(Uint8List png, String name) async {
    try {
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) return false;
      await Gal.putImageBytes(png, name: name);
      return true;
    } on GalException {
      return false;
    }
  }
}
