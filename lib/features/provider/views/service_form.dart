import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../locations/models/ph_address.dart';
import '../../locations/widgets/ph_address_picker.dart';
import '../models/commission_model.dart';
import '../models/provider_service_model.dart';
import '../services/commission_service.dart';
import '../services/provider_service_service.dart';

const _priceTypes = {'fixed': 'Fixed price', 'hourly': 'Per hour', 'custom': 'Custom quote'};

/// Shared create/edit form for a provider's service. Submits the API payload
/// for `POST`/`PUT /api/client/v1/provider/services`.
class ServiceForm extends StatefulWidget {
  final ProviderServiceModel? existing;
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
  late PhAddress _area = widget.existing?.locationDetails ?? PhAddress.empty;

  List<ServiceCategoryOption> _categories = [];
  bool _loadingCategories = true;
  String? _categoriesError;
  String? _categoryId;
  String? _subcategoryId;
  late String _priceType = widget.existing?.priceType ?? 'fixed';

  /// SkillServe's share of the typed price, so the provider sees what they
  /// keep before submitting. Null while the price is empty or invalid.
  CommissionSplit? _split;
  Timer? _previewTimer;
  int _previewRequest = 0;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.existing?.categoryId;
    _subcategoryId = widget.existing?.subcategoryId;
    _loadCategories();
    _price.addListener(_schedulePreview);
    _schedulePreview();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    for (final controller in [_title, _description, _price, _duration]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
    });
    try {
      final categories = await ProviderServiceService().getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        // Drop a selection that is no longer an enabled category.
        if (!categories.any((c) => c.id == _categoryId)) {
          _categoryId = null;
          _subcategoryId = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _categoriesError = 'Unable to load categories.');
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  /// Asks for the split once typing pauses. A newer request supersedes an
  /// older one, so a slow reply can never overwrite the current price's split.
  void _schedulePreview() {
    _previewTimer?.cancel();
    final amount = double.tryParse(_price.text.trim());
    if (amount == null || amount < 0) {
      _previewRequest++;
      if (_split != null) setState(() => _split = null);
      return;
    }
    _previewTimer = Timer(const Duration(milliseconds: 400), () => _loadPreview(amount));
  }

  Future<void> _loadPreview(double amount) async {
    final request = ++_previewRequest;
    CommissionSplit? split;
    try {
      split = await CommissionService().preview(amount);
    } catch (_) {
      // The split is advisory: without it the form still works, so a failed
      // preview simply shows nothing rather than an error.
    }
    if (mounted && request == _previewRequest) setState(() => _split = split);
  }

  List<ServiceSubcategoryOption> get _subcategories =>
      _categories.where((c) => c.id == _categoryId).firstOrNull?.subcategories ?? const [];

  String? _validatePrice(String? value) {
    final required = Validators.required(value, field: 'Price');
    if (required != null) return required;
    final price = double.tryParse(value!.trim());
    if (price == null || price < 0) return 'Enter a valid amount.';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit({
      'title': _title.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'category_id': int.parse(_categoryId!),
      'subcategory_id': _subcategoryId == null ? null : int.parse(_subcategoryId!),
      'price': double.parse(_price.text.trim()),
      'price_type': _priceType,
      'duration': _duration.text.trim().isEmpty ? null : _duration.text.trim(),
      // The area as codes; the API writes the readable `location` from it.
      'location_details': _area.toAreaJson(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCategories) return const LoadingState();
    if (_categoriesError != null) return ErrorState(message: _categoriesError!, onRetry: _loadCategories);

    final labelStyle = Theme.of(context).textTheme.labelMedium;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIcon(AppIcons.info_outline_rounded, color: AppColors.info, size: 18),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'An administrator reviews every new service before customers can see it.'
                        : 'Saving changes sends this service back for administrator approval. It is hidden from customers until approved.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: AppSizes.lg),
          AppTextField(label: 'Service title', hint: 'e.g. Aircon Cleaning', controller: _title, validator: Validators.required)
              .animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: AppSizes.lg),
          Text('Category', style: labelStyle),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            hint: const Text('Select a category'),
            isExpanded: true,
            items: [for (final c in _categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
            validator: (value) => value == null ? 'Please select a category.' : null,
            onChanged: (value) => setState(() {
              _categoryId = value;
              _subcategoryId = null;
            }),
          ),
          if (_subcategories.isNotEmpty) ...[
            const SizedBox(height: AppSizes.lg),
            Text('Subcategory (optional)', style: labelStyle),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              key: ValueKey(_categoryId),
              initialValue: _subcategories.any((s) => s.id == _subcategoryId) ? _subcategoryId : null,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('None')),
                for (final s in _subcategories) DropdownMenuItem<String?>(value: s.id, child: Text(s.name)),
              ],
              onChanged: (value) => setState(() => _subcategoryId = value),
            ),
          ],
          const SizedBox(height: AppSizes.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Price (₱)',
                  hint: '1500',
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validatePrice,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price type', style: labelStyle),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _priceType,
                      isExpanded: true,
                      items: [
                        for (final entry in _priceTypes.entries)
                          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                      ],
                      onChanged: (value) => setState(() => _priceType = value ?? _priceType),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_split != null) ...[
            const SizedBox(height: AppSizes.sm),
            _CommissionSplitNote(split: _split!, perHour: _priceType == 'hourly'),
          ],
          const SizedBox(height: AppSizes.lg),
          AppTextField(label: 'Duration', hint: 'e.g. 2 hours', controller: _duration),
          const SizedBox(height: AppSizes.lg),
          Text('Where you offer this service', style: labelStyle),
          const SizedBox(height: 6),
          if (widget.existing != null && widget.existing!.locationDetails == null && widget.existing!.location.isNotEmpty) ...[
            Text(
              'Saved before: ${widget.existing!.location}. Choose it below.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral300),
            ),
            const SizedBox(height: 6),
          ],
          PhAddressPicker(
            initial: _area,
            door: false,
            onChanged: (area) => _area = area,
          ),
          const SizedBox(height: AppSizes.lg),
          AppTextField(
            label: 'Description',
            hint: "Describe what's included in this service…",
            controller: _description,
            maxLines: 5,
          ),
          const SizedBox(height: AppSizes.xxl),
          PrimaryButton(
            label: widget.existing == null ? 'Submit for approval' : 'Save and send for approval',
            isLoading: widget.submitting,
            onPressed: widget.submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

/// "SkillServe 15% · ₱75.00 · you keep ₱425.00" under the price field.
class _CommissionSplitNote extends StatelessWidget {
  final CommissionSplit split;
  final bool perHour;

  const _CommissionSplitNote({required this.split, required this.perHour});

  @override
  Widget build(BuildContext context) {
    final unit = perHour ? ' per hour' : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppIcon(AppIcons.info_outline_rounded, color: AppColors.neutral300, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            // Exact amounts, as the Commissions screen shows them: rounding
            // to whole pesos could make the two shares not add up.
            'SkillServe ${split.rateLabel} · ₱${split.commissionAmount} · '
            'you keep ₱${split.netAmount}$unit',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral300),
          ),
        ),
      ],
    );
  }
}
