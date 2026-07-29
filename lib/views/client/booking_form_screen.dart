import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../models/provider_model.dart';
import '../../services/booking_service.dart';
import '../../services/service_service.dart';

/// Booking creation form — date, time slot, address, and notes.
/// On submit, creates a mock booking and routes to the confirmation screen.
class BookingFormScreen extends StatefulWidget {
  final String providerId;
  const BookingFormScreen({super.key, required this.providerId});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _bookingService = BookingService();

  ProviderModel? _provider;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _slot = '9:00 AM';
  bool _submitting = false;

  final _slots = const ['8:00 AM', '9:00 AM', '10:00 AM', '1:00 PM', '3:00 PM', '5:00 PM'];

  @override
  void initState() {
    super.initState();
    ServiceService().getProviderById(widget.providerId).then((p) {
      if (mounted) setState(() => _provider = p);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_addressController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final booking = await _bookingService.createBooking(
      providerId: widget.providerId,
      serviceId: 'SV-${widget.providerId}',
      date: _date,
      schedule: _slot,
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
    );
    setState(() => _submitting = false);
    if (mounted) context.pushReplacement('/booking-confirmation', extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    if (_provider == null) return const Scaffold(body: LoadingState());
    final p = _provider!;

    return Scaffold(
      appBar: AppBar(title: const Text('Book a Service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 22, backgroundColor: AppColors.primary, child: Text(p.user.initials, style: const TextStyle(color: Colors.white))),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.user.fullName, style: AppTextStyles.titleMedium),
                          Text(p.categoryName, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    if (p.startingPrice != null)
                      Text(Formatters.peso(p.startingPrice!), style: AppTextStyles.titleMedium.copyWith(color: AppColors.secondary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Text('Select a date', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSizes.sm),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.secondary),
                      const SizedBox(width: AppSizes.sm),
                      Text(Formatters.dateShort(_date), style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Text('Select a time slot', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in _slots)
                    ChoiceChip(
                      label: Text(slot),
                      selected: _slot == slot,
                      onSelected: (_) => setState(() => _slot = slot),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              AppTextField(
                label: 'Service address',
                hint: 'Where should the provider go?',
                controller: _addressController,
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Notes (optional)',
                hint: 'Describe the issue or any special instructions…',
                controller: _notesController,
                maxLines: 4,
              ),
              const SizedBox(height: AppSizes.xxxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: PrimaryButton(label: 'Confirm booking', isLoading: _submitting, onPressed: _submit),
        ),
      ),
    );
  }
}
