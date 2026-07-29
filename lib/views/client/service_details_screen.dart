import 'package:flutter/material.dart';
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
              ),
              const SizedBox(height: AppSizes.lg),
              Text(s.title, style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  _Pill(icon: Icons.payments_outlined, label: Formatters.peso(s.price)),
                  const SizedBox(width: AppSizes.sm),
                  _Pill(icon: Icons.timer_outlined, label: s.duration),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              Text('Description', style: AppTextStyles.titleLarge),
              const SizedBox(height: 6),
              Text(s.description, style: AppTextStyles.bodyLarge),
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
            icon: Icons.calendar_month_rounded,
            onPressed: () => context.push('/booking-form/${s.providerId}'),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
