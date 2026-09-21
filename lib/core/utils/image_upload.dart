import 'package:dio/dio.dart';

/// An image file as a multipart part the API will accept.
///
/// The API only takes JPG, PNG and WebP, so the part is labelled from the
/// file's extension rather than sent as octet-stream, and keeps its filename.
Future<MultipartFile> imageMultipart(String imagePath) {
  final path = imagePath.replaceFirst('file://', '');
  return MultipartFile.fromFile(
    path,
    filename: _basename(path),
    contentType: _mediaTypeFor(path),
  );
}

String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

DioMediaType _mediaTypeFor(String path) {
  final name = _basename(path).toLowerCase();
  if (name.endsWith('.png')) return DioMediaType('image', 'png');
  if (name.endsWith('.webp')) return DioMediaType('image', 'webp');
  return DioMediaType('image', 'jpeg');
}
