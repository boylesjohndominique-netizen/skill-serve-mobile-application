import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Book a Service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider summary
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
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
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppSizes.xl),

              // Date picker
              Text('Select a date', style: AppTextStyles.titleLarge)
                  .animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.sm),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.secondary),
                      const SizedBox(width: AppSizes.sm),
                      Text(Formatters.dateShort(_date), style: AppTextStyles.bodyLarge),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),

              // Time slots
              Text('Select a time slot', style: AppTextStyles.titleLarge)
                  .animate().fadeIn(delay: 220.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _slots.length; i++)
                    ChoiceChip(
                      label: Text(_slots[i]),
                      selected: _slot == _slots[i],
                      onSelected: (_) => setState(() => _slot = _slots[i]),
                    ).animate().fadeIn(delay: Duration(milliseconds: 280 + i * 40), duration: 300.ms).slideX(begin: 0.08, end: 0),
                ],
              ),
              const SizedBox(height: AppSizes.xl),

              // Address & notes
              AppTextField(
                label: 'Service address',
                hint: 'Where should the provider go?',
                controller: _addressController,
                prefixIcon: Icons.location_on_outlined,
              ).animate().fadeIn(delay: 400.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Notes (optional)',
                hint: 'Describe the issue or any special instructions…',
                controller: _notesController,
                maxLines: 4,
              ).animate().fadeIn(delay: 470.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
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
