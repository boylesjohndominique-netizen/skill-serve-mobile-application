import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import 'private_image.dart';

/// Photos the user sent as proof, shown as a row of thumbnails; tapping one
/// opens them full screen (swipe between them, pinch to zoom). The photos are
/// private, so each is loaded with the user's token ([PrivateImage]).
class PrivatePhotoStrip extends StatelessWidget {
  final List<String> urls;
  final double size;

  const PrivatePhotoStrip({super.key, required this.urls, this.size = 64});

  void _open(BuildContext context, int index) {
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullScreen(urls: urls, initial: index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: [
        for (var i = 0; i < urls.length; i++)
          Semantics(
            button: true,
            label: 'Photo ${i + 1} of ${urls.length}. Open full screen',
            child: GestureDetector(
              onTap: () => _open(context, i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: PrivateImage(url: urls[i], width: size, height: size),
              ),
            ),
          ),
      ],
    );
  }
}

class _FullScreen extends StatelessWidget {
  final List<String> urls;
  final int initial;
  const _FullScreen({required this.urls, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: urls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(child: PrivateImage(url: urls[i], fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
