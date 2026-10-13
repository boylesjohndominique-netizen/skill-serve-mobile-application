import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../reports/views/report_content_sheet.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../marketplace/models/service_model.dart';
import '../../marketplace/services/catalog_updates.dart';
import '../../marketplace/services/service_service.dart';
import '../../../core/widgets/misc/app_avatar.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// One published service: what it is, what it costs, who offers it (tap
/// through to their profile), booking it and reporting it. Follows
/// [CatalogUpdates], so an edit the provider makes shows while it is open.
class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  ServiceModel? _service;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    CatalogUpdates.instance.addListener(_onCatalogChanged);
    _load();
  }

  @override
  void dispose() {
    CatalogUpdates.instance.removeListener(_onCatalogChanged);
    super.dispose();
  }

  /// A live update re-reads the listing; if it was hidden or removed, the
  /// screen says it is no longer available.
  void _onCatalogChanged() {
    if (_service != null) _load(silent: true);
  }

  /// [silent] is a live refresh: only "this listing is gone" (404) replaces
  /// the page; a dropped connection keeps the listing already shown.
  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _failed = false);
    try {
      final service = await ServiceService().getServiceById(widget.serviceId);
      if (mounted) setState(() => _service = service);
    } catch (e) {
      if (silent && !_isGone(e)) return;
      if (mounted) setState(() => _failed = true);
    }
  }

  void _report(ServiceModel service) =>
      showReportContentSheet(context, serviceId: service.id, title: 'Report this service');

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Details')),
        body: ErrorState(message: 'This service is no longer available.', onRetry: _load),
      );
    }
    if (_service == null) return const Scaffold(body: LoadingState());
    final s = _service!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Only a signed-in customer reports a listing; guests have no account,
    // and providers never see other providers' services.
    final canReport = context.select<AuthController, bool>((auth) => auth.isClient);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
        actions: [
          if (canReport)
            IconButton(
              tooltip: 'Report this service',
              icon: const AppIcon(AppIcons.flag_outlined),
              onPressed: () => _report(s),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: s.coverImage.isEmpty
                    ? Container(
                        height: 200,
                        width: double.infinity,
                        color: AppColors.secondarySoft,
                        alignment: Alignment.center,
                        child: const AppIcon(AppIcons.design_services_rounded, color: AppColors.secondaryDeep, size: 48),
                      )
                    : CachedNetworkImage(
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
              if (s.categoryName.isNotEmpty || s.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  [if (s.categoryName.isNotEmpty) s.categoryName, if (s.location.isNotEmpty) s.location].join(' • '),
                  style: AppTextStyles.bodySmall,
                ),
              ],
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  _Pill(
                    icon: AppIcons.payments_outlined,
                    label: s.isQuoteOnly ? 'On quote' : Formatters.peso(s.price),
                    isDark: isDark,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  _Pill(icon: AppIcons.timer_outlined, label: s.duration, isDark: isDark),
                ],
              ).animate().fadeIn(delay: 180.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),
              Text('Description', style: AppTextStyles.titleLarge)
                  .animate().fadeIn(delay: 260.ms, duration: 300.ms),
              const SizedBox(height: 6),
              Text(
                s.description.trim().isEmpty ? 'The provider has not added a description.' : s.description,
                style: AppTextStyles.bodyLarge,
              ).animate().fadeIn(delay: 320.ms, duration: 300.ms),
              if (s.providerId.isNotEmpty) ...[
                const SizedBox(height: AppSizes.xl),
                Text('Offered by', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSizes.sm),
                _ProviderTile(
                  name: s.providerName,
                  onTap: () => context.push('/provider-profile/${s.providerId}'),
                ).animate().fadeIn(delay: 360.ms, duration: 300.ms),
              ],
              if (canReport) ...[
                const SizedBox(height: AppSizes.lg),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _report(s),
                    icon: AppIcon(AppIcons.flag_outlined, size: 16, color: context.textMutedColor),
                    label: Text(
                      'Report this service',
                      style: AppTextStyles.label.copyWith(color: context.textMutedColor),
                    ),
                  ),
                ),
              ],
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
            onPressed: () => context.push('/booking-form/${s.providerId}?serviceId=${s.id}'),
          ),
        ),
      ),
    );
  }
}

/// Who offers the service; opens their full profile.
/// The API no longer lists it: hidden, unpublished, or its provider removed.
bool _isGone(Object error) => error is DioException && error.response?.statusCode == 404;

class _ProviderTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _ProviderTile({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
          ),
          child: Row(
            children: [
              AppAvatar(
                name: name,
                radius: 20,
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                    Text('View profile, portfolio and reviews', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              AppIcon(AppIcons.chevron_right_rounded, color: context.textMutedColor),
            ],
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
          AppIcon(icon, size: 15, color: context.accentInk),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
