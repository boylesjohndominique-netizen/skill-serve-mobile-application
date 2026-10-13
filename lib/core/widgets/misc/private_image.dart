import 'dart:collection';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../services/api_client.dart';
import '../../theme/app_palette.dart';
import '../feedback/shimmer_placeholder.dart';
import 'app_icon.dart';

/// An image only the signed-in user may see (a photo sent in chat): loaded
/// through the API client, so it carries the user's token and survives a
/// token renewal, and kept in a small in-memory cache so scrolling a thread
/// does not download it again.
class PrivateImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const PrivateImage({super.key, required this.url, this.fit = BoxFit.cover, this.width, this.height});

  /// Recently shown images, newest last. Bounded so a long chat cannot hold
  /// every photo in memory.
  static final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();
  static const _cacheSize = 40;

  /// The image's bytes, from the cache or the API.
  static Future<Uint8List> load(String url) async {
    final cached = _cache.remove(url);
    if (cached != null) return _cache[url] = cached;

    final response = await ApiClient.instance.dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(response.data ?? const []);
    _cache[url] = bytes;
    if (_cache.length > _cacheSize) _cache.remove(_cache.keys.first);
    return bytes;
  }

  @override
  State<PrivateImage> createState() => _PrivateImageState();
}

class _PrivateImageState extends State<PrivateImage> {
  late Future<Uint8List> _bytes = PrivateImage.load(widget.url);

  @override
  void didUpdateWidget(PrivateImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _bytes = PrivateImage.load(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _broken(context),
          );
        }
        if (snapshot.hasError) {
          return GestureDetector(
            // A tap tries again — the connection may have dropped.
            onTap: () => setState(() => _bytes = PrivateImage.load(widget.url)),
            child: _broken(context),
          );
        }
        return SizedBox(width: widget.width, height: widget.height, child: const ShimmerPlaceholder());
      },
    );
  }

  Widget _broken(BuildContext context) => Container(
        width: widget.width,
        height: widget.height,
        color: context.surfaceAltColor,
        alignment: Alignment.center,
        child: AppIcon(AppIcons.broken_image_outlined, color: context.textMutedColor),
      );
}
