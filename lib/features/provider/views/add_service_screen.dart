import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../controllers/provider_services_controller.dart';
import 'service_form.dart';

class AddServiceScreen extends StatelessWidget {
  const AddServiceScreen({super.key});

  Future<void> _submit(BuildContext context, Map<String, dynamic> values) async {
    final controller = context.read<ProviderServicesController>();
    final created = await controller.create(values);
    if (!context.mounted) return;

    if (created) {
      AppSnackbar.success(context, 'Service submitted. You will be notified once an administrator reviews it.');
      context.pop();
    } else {
      AppSnackbar.error(context, controller.errorMessage ?? 'Unable to submit the service.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.select<ProviderServicesController, bool>((c) => c.isSaving);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: ServiceForm(onSubmit: (values) => _submit(context, values), submitting: submitting),
        ),
      ),
    );
  }
}
