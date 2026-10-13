import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

/// Captures one side of a National ID and returns the image's file path, or
/// null when the user backs out.
typedef CaptureIdPhoto = Future<String?> Function();

/// The camera for the National ID: Google's ML Kit Document Scanner, the
/// same kind of screen KYC apps use. It finds the card's edges by itself,
/// captures when the card is steady, and straightens and crops it — so the
/// text and QR code are read from a flat image of the card alone rather than
/// a photo of a table with a card on it.
///
/// It runs in the base mode: crop and rotate only. The other modes offer
/// colour filters and erase "stains" and fingers, and a reviewer must see
/// the card exactly as the camera did.
///
/// Phones without Google Play services cannot run it; they fall back to the
/// plain camera so sign-up still works.
Future<String?> captureNationalIdPhoto() async {
  final scanner = DocumentScanner(
    options: DocumentScannerOptions(
      documentFormats: {DocumentFormat.jpeg},
      pageLimit: 1,
      mode: ScannerMode.base,
      isGalleryImport: false,
    ),
  );
  try {
    final result = await scanner.scanDocument();
    final images = result.images ?? const <String>[];
    return images.isEmpty ? null : images.first;
  } on PlatformException catch (e) {
    if ((e.message ?? '').toLowerCase().contains('cancel')) return null;
    debugPrint('[NationalId] document scanner unavailable (${e.message}); using the camera');
    final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90, maxWidth: 2400);
    return file?.path;
  } finally {
    try {
      await scanner.close();
    } catch (_) {
      // Nothing was started, so there is nothing to release.
    }
  }
}

/// A photo the plain camera took while Android closed the app, handed back
/// once the app is open again; null when there is none. The document scanner
/// cannot do this, so a side it was capturing is simply taken again.
Future<String?> recoverLostNationalIdPhoto() async {
  if (defaultTargetPlatform != TargetPlatform.android) return null;
  try {
    final lost = await ImagePicker().retrieveLostData();
    return lost.isEmpty ? null : lost.file?.path;
  } catch (_) {
    return null;
  }
}
