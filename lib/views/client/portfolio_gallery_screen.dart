import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../models/provider_model.dart';
import '../../services/service_service.dart';
import '../../core/constants/app_icons.dart';

/// Full portfolio gallery for a provider — grid of past work, tap to view
/// full-screen.
class PortfolioGalleryScreen extends StatefulWidget {
  final String providerId;
  const PortfolioGalleryScreen({super.key, required this.providerId});

  @override
  State<PortfolioGalleryScreen> createState() => _PortfolioGalleryScreenState();
}

class _PortfolioGalleryScreenState extends State<PortfolioGalleryScreen> {
  ProviderModel? _provider;

  @override
  void initState() {
    super.initState();
    ServiceService().getProviderById(widget.providerId).then((p) {
      if (mounted) setState(() => _provider = p);
    });
  }

  void _openFull(String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, _, __) => Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_provider == null) return const Scaffold(body: LoadingState());
    final images = _provider!.portfolioImages;

    return Scaffold(
      appBar: AppBar(title: Text('${_provider!.user.fullName}\'s Work')),
      body: SafeArea(
        child: images.isEmpty
            ? const EmptyState(icon: AppIcons.photo_library_outlined, title: 'No portfolio yet', message: 'This provider hasn\'t uploaded work samples.')
            : GridView.builder(
                padding: const EdgeInsets.all(AppSizes.pageHPad),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSizes.sm,
                  crossAxisSpacing: AppSizes.sm,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, i) => InkWell(
                  onTap: () => _openFull(images[i]),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      placeholder: (c, u) => const ShimmerPlaceholder(),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                    .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack),
              ),
      ),
    );
  }
}
