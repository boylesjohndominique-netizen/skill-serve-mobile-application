import 'dart:typed_data';
import 'dart:ui' as ui;

/// What can make a National ID photo unusable for review.
enum IdPhotoIssue {
  tooSmall('This photo is too small to read. Fill the frame with the card and try again.'),
  tooDark('This photo is too dark. Move to brighter light and try again.'),
  washedOut('This photo is washed out by light or glare. Tilt the card away from the light and try again.'),
  blurry('This photo is blurry. Hold the phone steady, let it focus on the card, and try again.');

  const IdPhotoIssue(this.message);

  /// What the user is told, with how to fix it.
  final String message;
}

/// Checks a National ID photo on the phone before it is kept, so a reviewer
/// is not sent a card they cannot read: big enough, not too dark, not washed
/// out, and in focus.
///
/// The thresholds are deliberately forgiving — they catch photos a person
/// would also call unreadable, not ones that are merely imperfect. The server
/// enforces the minimum size again; the reviewer remains the final check.
class IdPhotoQuality {
  const IdPhotoQuality._();

  /// The card's shorter and longer sides must reach these, in pixels. The
  /// API refuses smaller photos with the same numbers.
  static const minShortSide = 500;
  static const minLongSide = 800;

  /// Photos are judged at this width, so the blur measure means the same for
  /// a 12 MP camera as for a 2 MP one.
  static const analysisWidth = 800;

  /// Average brightness (0–255) below which the card is too dark to read.
  static const minMeanLuminance = 55.0;

  /// Average brightness above which the photo is washed out.
  static const maxMeanLuminance = 235.0;

  /// Share of fully blown-out pixels above which glare hides the card. High,
  /// because the PhilSys card is mostly white.
  static const maxClippedShare = 0.35;

  /// Variance of the Laplacian (edge sharpness) below which the photo is
  /// blurry. Text on a card in focus measures in the hundreds.
  static const minSharpness = 35.0;

  /// Decodes [bytes] and checks them; null when the photo is fine. A photo
  /// that cannot be decoded is passed through — the upload checks decide.
  static Future<IdPhotoIssue?> check(Uint8List bytes) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width;
      final height = descriptor.height;
      if (isTooSmall(width, height)) return IdPhotoIssue.tooSmall;

      codec = await descriptor.instantiateCodec(targetWidth: width > analysisWidth ? analysisWidth : width);
      image = (await codec.getNextFrame()).image;
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (pixels == null) return null;
      return analyze(pixels.buffer.asUint8List(), image.width, image.height);
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  /// Whether a [width] × [height] photo is below the minimum, in either
  /// orientation.
  static bool isTooSmall(int width, int height) {
    final short = width < height ? width : height;
    final long = width < height ? height : width;
    return short < minShortSide || long < minLongSide;
  }

  /// Checks decoded RGBA [pixels] ([width] × [height]); null when fine.
  static IdPhotoIssue? analyze(Uint8List pixels, int width, int height) {
    final count = width * height;
    if (count == 0 || pixels.length < count * 4) return null;

    final luminance = Float64List(count);
    var sum = 0.0;
    var clipped = 0;
    for (var i = 0, p = 0; i < count; i++, p += 4) {
      final r = pixels[p], g = pixels[p + 1], b = pixels[p + 2];
      final y = 0.299 * r + 0.587 * g + 0.114 * b;
      luminance[i] = y;
      sum += y;
      if (r >= 252 && g >= 252 && b >= 252) clipped++;
    }

    final mean = sum / count;
    if (mean < minMeanLuminance) return IdPhotoIssue.tooDark;
    if (mean > maxMeanLuminance || clipped / count > maxClippedShare) return IdPhotoIssue.washedOut;
    if (sharpness(luminance, width, height) < minSharpness) return IdPhotoIssue.blurry;
    return null;
  }

  /// Variance of the 4-neighbour Laplacian over [luminance]: high where the
  /// photo has crisp edges (text, the photo, the QR code), low when blurred.
  static double sharpness(Float64List luminance, int width, int height) {
    if (width < 3 || height < 3) return 0;
    var sum = 0.0;
    var sumSquares = 0.0;
    var n = 0;
    for (var y = 1; y < height - 1; y++) {
      final row = y * width;
      for (var x = 1; x < width - 1; x++) {
        final i = row + x;
        final laplacian = luminance[i - 1] + luminance[i + 1] + luminance[i - width] + luminance[i + width] - 4 * luminance[i];
        sum += laplacian;
        sumSquares += laplacian * laplacian;
        n++;
      }
    }
    final mean = sum / n;
    return sumSquares / n - mean * mean;
  }
}
