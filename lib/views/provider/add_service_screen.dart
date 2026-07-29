import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import 'service_form.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  bool _submitting = false;

  Future<void> _submit(Map<String, dynamic> values) async {
    setState(() => _submitting = true);
    // Placeholder — POST /services once the backend exists.
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _submitting = false);
    if (mounted) {
      AppSnackbar.success(context, 'Service added to your listings.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: ServiceForm(onSubmit: _submit, submitting: _submitting),
        ),
      ),
    );
  }
}
