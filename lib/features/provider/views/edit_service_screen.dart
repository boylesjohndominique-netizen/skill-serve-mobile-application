import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../controllers/provider_services_controller.dart';
import '../models/provider_service_model.dart';
import '../services/provider_service_service.dart';
import 'service_form.dart';

class EditServiceScreen extends StatefulWidget {
  final String serviceId;
  const EditServiceScreen({super.key, required this.serviceId});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  ProviderServiceModel? _service;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final service = await ProviderServiceService().getMyService(widget.serviceId);
      if (mounted) setState(() => _service = service);
    } catch (e) {
      if (mounted) setState(() => _loadError = apiErrorMessage(e, 'Unable to load this service.'));
    }
  }

  Future<void> _submit(Map<String, dynamic> values) async {
    final controller = context.read<ProviderServicesController>();
    final saved = await controller.update(widget.serviceId, values);
    if (!mounted) return;

    if (saved) {
      AppSnackbar.success(context, 'Changes sent for approval. You will be notified once reviewed.');
      context.pop();
    } else {
      AppSnackbar.error(context, controller.errorMessage ?? 'Unable to save your changes.');
    }
  }

  Future<void> _delete() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete this service?',
      message: 'Customers will no longer be able to find or book it.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    final controller = context.read<ProviderServicesController>();
    final deleted = await controller.delete(widget.serviceId);
    if (!mounted) return;

    if (deleted) {
      AppSnackbar.success(context, 'Service deleted.');
      context.pop();
    } else {
      AppSnackbar.error(context, controller.errorMessage ?? 'Unable to delete the service.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.select<ProviderServicesController, bool>((c) => c.isSaving);
    final service = _service;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Service'),
        actions: [
          if (service != null)
            IconButton(
              tooltip: 'Delete service',
              icon: const AppIcon(AppIcons.delete_outline_rounded),
              onPressed: submitting ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: _loadError != null
            ? ErrorState(message: _loadError!, onRetry: _load)
            : service == null
                ? const LoadingState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.pageHPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (service.isRejected && (service.rejectionReason ?? '').isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            ),
                            child: Text(
                              'Rejected: ${service.rejectionReason}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                        ],
                        ServiceForm(existing: service, onSubmit: _submit, submitting: submitting),
                      ],
                    ),
                  ),
      ),
    );
  }
}
