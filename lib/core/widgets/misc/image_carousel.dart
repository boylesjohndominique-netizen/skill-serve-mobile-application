import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../feedback/shimmer_placeholder.dart';

/// Swipeable image gallery used on provider profiles and portfolio galleries.
/// Features smoother page indicators and improved dot indicator design.
class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;

  const ImageCarousel({super.key, required this.images, this.height = 240});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.neutral300, size: 40),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => const ShimmerPlaceholder(),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surfaceAlt,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, color: AppColors.neutral300),
                  ),
                ),
              ),
            ),
          ),
          // Gradient overlay at bottom for indicator readability
          if (widget.images.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                  ),
                ),
              ),
            ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: AppAnimations.md,
                    curve: AppAnimations.defaultCurve,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: i == _index
                          ? [BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 4)]
                          : [],
                    ),
                  ),
                ),
              ),
            ),
          // Image counter badge
          if (widget.images.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text(
                  '${_index + 1}/${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
