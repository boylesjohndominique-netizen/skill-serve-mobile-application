import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../models/service_model.dart';
import '../../services/service_service.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  ServiceModel? _service;

  @override
  void initState() {
    super.initState();
    ServiceService().getServiceById(widget.serviceId).then((s) {
      if (mounted) setState(() => _service = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null) return const Scaffold(body: LoadingState());
    final s = _service!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Service Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: CachedNetworkImage(
                  imageUrl: s.coverImage,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => const ShimmerPlaceholder(height: 200),
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0),
              const SizedBox(height: AppSizes.lg),
              Text(s.title, style: AppTextStyles.headlineLarge)
                  .animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  _Pill(icon: AppIcons.payments_outlined, label: Formatters.peso(s.price), isDark: isDark),
                  const SizedBox(width: AppSizes.sm),
                  _Pill(icon: AppIcons.timer_outlined, label: s.duration, isDark: isDark),
                ],
              ).animate().fadeIn(delay: 180.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),
              Text('Description', style: AppTextStyles.titleLarge)
                  .animate().fadeIn(delay: 260.ms, duration: 300.ms),
              const SizedBox(height: 6),
              Text(s.description, style: AppTextStyles.bodyLarge)
                  .animate().fadeIn(delay: 320.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xxxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: PrimaryButton(
            label: 'Book this service',
            icon: AppIcons.calendar_month_rounded,
            onPressed: () => context.push('/booking-form/${s.providerId}'),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final AppIconData icon;
  final String label;
  final bool isDark;
  const _Pill({required this.icon, required this.label, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 15, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
