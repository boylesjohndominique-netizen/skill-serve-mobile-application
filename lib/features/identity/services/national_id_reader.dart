import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Reads a photo of a National ID on the phone itself (Google ML Kit, on
/// device): the printed text on the front and the QR code on the back. The
/// photo is never sent anywhere to be read.
///
/// An interface so the sign-up flow is tested with a fake reader.
abstract class NationalIdReader {
  /// The recognised text, one printed line per line.
  Future<String> readText(String imagePath);

  /// The raw contents of every QR code found.
  Future<List<String>> readQrCodes(String imagePath);

  Future<void> close();
}

class MlKitNationalIdReader implements NationalIdReader {
  final _text = TextRecognizer(script: TextRecognitionScript.latin);
  final _qr = BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  @override
  Future<String> readText(String imagePath) async {
    final result = await _text.processImage(InputImage.fromFilePath(imagePath));
    return [
      for (final block in result.blocks)
        for (final line in block.lines) line.text,
    ].join('\n');
  }

  @override
  Future<List<String>> readQrCodes(String imagePath) async {
    final codes = await _qr.processImage(InputImage.fromFilePath(imagePath));
    return [for (final code in codes) if (code.rawValue != null) code.rawValue!];
  }

  @override
  Future<void> close() async {
    await _text.close();
    await _qr.close();
  }
}
