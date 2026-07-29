import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../data/mock/mock_data.dart';
import '../../models/service_model.dart';

/// Shared create/edit form for a provider's service listing.
class ServiceForm extends StatefulWidget {
  final ServiceModel? existing;
  final Future<void> Function(Map<String, dynamic> values) onSubmit;
  final bool submitting;

  const ServiceForm({super.key, this.existing, required this.onSubmit, required this.submitting});

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description = TextEditingController(text: widget.existing?.description);
  late final _price = TextEditingController(text: widget.existing?.price.toStringAsFixed(0));
  late final _duration = TextEditingController(text: widget.existing?.duration);
  String _category = MockData.categories.first.name;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final cat = MockData.categories.where((c) => c.id == widget.existing!.categoryId);
      if (cat.isNotEmpty) _category = cat.first.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: 'Service title', hint: 'e.g. Bathroom Pipe Repair', controller: _title, validator: Validators.required),
          const SizedBox(height: AppSizes.lg),
          Text('Category', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: [for (final c in MockData.categories) DropdownMenuItem(value: c.name, child: Text(c.name))],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Price (₱)',
                  hint: '500',
                  controller: _price,
                  keyboardType: TextInputType.number,
                  validator: Validators.required,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: AppTextField(label: 'Duration', hint: 'e.g. 1–2 hrs', controller: _duration, validator: Validators.required),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          AppTextField(
            label: 'Description',
            hint: 'Describe what\'s included in this service…',
            controller: _description,
            maxLines: 5,
            validator: Validators.required,
          ),
          const SizedBox(height: AppSizes.xxl),
          PrimaryButton(
            label: widget.existing == null ? 'Add service' : 'Save changes',
            isLoading: widget.submitting,
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              widget.onSubmit({
                'title': _title.text.trim(),
                'category': _category,
                'price': double.tryParse(_price.text.trim()) ?? 0,
                'duration': _duration.text.trim(),
                'description': _description.text.trim(),
              });
            },
          ),
        ],
      ),
    );
  }
}
