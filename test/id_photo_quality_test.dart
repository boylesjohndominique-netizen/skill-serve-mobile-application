import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/identity/services/id_photo_quality.dart';

/// An RGBA image [width] × [height] coloured by [shade] (x, y) → grey level.
Uint8List _image(int width, int height, int Function(int x, int y) shade) {
  final pixels = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final p = (y * width + x) * 4;
      final v = shade(x, y);
      pixels[p] = v;
      pixels[p + 1] = v;
      pixels[p + 2] = v;
      pixels[p + 3] = 255;
    }
  }
  return pixels;
}

void main() {
  const w = 200, h = 126;

  /// Dark "text" strokes on a light card: crisp edges every few pixels.
  int sharpCard(int x, int y) => (x % 6 < 2 && y % 10 < 7) ? 40 : 215;

  test('a sharp, well-lit card passes', () {
    expect(IdPhotoQuality.analyze(_image(w, h, sharpCard), w, h), isNull);
  });

  test('a photo with no edges at all is blurry', () {
    // A smooth gradient: lit fine, but nothing in focus.
    expect(IdPhotoQuality.analyze(_image(w, h, (x, _) => 120 + x ~/ 4), w, h), IdPhotoIssue.blurry);
  });

  test('a dark photo is too dark', () {
    expect(IdPhotoQuality.analyze(_image(w, h, (x, y) => sharpCard(x, y) ~/ 6), w, h), IdPhotoIssue.tooDark);
  });

  test('a blown-out photo is washed out', () {
    // Mostly pure white with a little text left.
    expect(
      IdPhotoQuality.analyze(_image(w, h, (x, y) => (x < 40 && x % 6 < 2) ? 40 : 255), w, h),
      IdPhotoIssue.washedOut,
    );
  });

  test('a white card that is not blown out is not mistaken for glare', () {
    expect(IdPhotoQuality.analyze(_image(w, h, (x, y) => (x % 8 < 2 && y % 10 < 7) ? 40 : 240), w, h), isNull);
  });

  test('the minimum size holds in either orientation', () {
    expect(IdPhotoQuality.isTooSmall(1200, 760), isFalse);
    expect(IdPhotoQuality.isTooSmall(760, 1200), isFalse);
    expect(IdPhotoQuality.isTooSmall(640, 400), isTrue);
    expect(IdPhotoQuality.isTooSmall(400, 900), isTrue);
  });
}
