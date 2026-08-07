import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../models/service_model.dart';
import '../../services/service_service.dart';
import 'service_form.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

class EditServiceScreen extends StatefulWidget {
  final String serviceId;
  const EditServiceScreen({super.key, required this.serviceId});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  ServiceModel? _service;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    ServiceService().getServiceById(widget.serviceId).then((s) {
      if (mounted) setState(() => _service = s);
    });
  }

  Future<void> _submit(Map<String, dynamic> values) async {
    setState(() => _submitting = true);
    // Placeholder — PUT /services/:id once the backend exists.
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _submitting = false);
    if (mounted) {
      AppSnackbar.success(context, 'Service updated.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Service'),
        actions: [
          IconButton(
            icon: const AppIcon(AppIcons.delete_outline_rounded),
            onPressed: () async {
              // Placeholder — DELETE /services/:id once the backend exists.
              if (context.mounted) {
                AppSnackbar.success(context, 'Service removed from your listings.');
                context.pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _service == null
            ? const LoadingState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pageHPad),
                child: ServiceForm(existing: _service, onSubmit: _submit, submitting: _submitting),
              ),
      ),
    );
  }
}
