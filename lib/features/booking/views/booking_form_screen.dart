import 'package:flutter/material.dart';
import '../../locations/models/ph_address.dart';
import '../../locations/widgets/ph_address_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../marketplace/models/provider_model.dart';
import '../../marketplace/models/service_model.dart';
import '../../../core/utils/api_error.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'schedule_picker.dart';
import '../../marketplace/services/service_service.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// Presentation for the two payment methods the API accepts
/// ({@link BookingModel.paymentMethods}). Selection only: nothing is charged
/// here, because the customer pays the provider directly.
const _paymentIcons = <String, AppIconData>{
  'on_hand': AppIcons.payments_outlined,
  'gcash': AppIcons.account_balance_wallet_rounded,
};

const _paymentBlurbs = <String, String>{
  'on_hand': 'Hand the payment to the provider when the job is done',
  'gcash': 'Send it to the provider\'s own GCash number',
};

/// SkillServe 4-step booking wizard —
/// 1 Service → 2 Schedule → 3 Details & Payment → 4 Confirm.
class BookingFormScreen extends StatefulWidget {
  final String providerId;
  const BookingFormScreen({super.key, required this.providerId});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _bookingService = BookingService();
  late final TextEditingController _phoneController;
  /// Where the provider should go: starts from the customer's saved address.
  late PhAddress _address;
  final _notesController = TextEditingController();

  /// The signed-in customer's name, shown on the review step. It is not sent:
  /// the booking is already tied to the account that creates it.
  String _clientName = '';

  ProviderModel? _provider;
  List<ServiceModel> _services = [];
  bool _loading = true;

  int _step = 0;
  ServiceModel? _selectedService;
  DateTime _date = DateTime.now().add(const Duration(days: 1));

  /// Chosen start time as minutes from midnight; null until one is picked,
  /// because a provider's published window decides what is on offer.
  int? _slotMinutes;
  String _paymentMethod = BookingModel.paymentMethods.first.$1;
  bool _submitting = false;

  /// One key for this wizard, so a retried or double-tapped submit returns
  /// the booking already created instead of making a second one.
  final String _idempotencyKey = 'booking-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    _clientName = user?.fullName ?? '';
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _address = user?.addressDetails ?? PhAddress.empty;
    _load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ProviderModel provider;
    try {
      // The provider detail includes its bookable (approved, public) services.
      provider = await ServiceService().getProviderById(widget.providerId);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final services = provider.services;
    if (mounted) {
      setState(() {
        _provider = provider;
        _services = services;
        _selectedService = services.isEmpty ? null : services.first;
        _loading = false;
      });
      _selectFirstSlot();
    }
  }

  /// Start times that fit the chosen service inside the provider's hours
  /// for [_date] — see [BookingSlots.options].
  List<int> get _slotOptions => BookingSlots.options(
        _provider?.availability ?? const [],
        _date,
        _selectedService?.durationMinutes ?? 60,
      );

  /// A longer service leaves fewer start times inside the provider's window,
  /// so a slot chosen for a shorter one is re-picked rather than silently
  /// submitted and refused by the API.
  void _selectService(ServiceModel service) {
    setState(() => _selectedService = service);
    if (!_slotOptions.contains(_slotMinutes)) _selectFirstSlot();
  }

  void _selectFirstSlot() {
    final slots = _slotOptions;
    setState(() => _slotMinutes = slots.isEmpty ? null : slots.first);
  }

  bool get _stepValid {
    switch (_step) {
      case 0:
        return _selectedService != null;
      case 1:
        return _slotMinutes != null;
      case 2:
        return Validators.phone(_phoneController.text) == null && _address.hasBarangay;
      default:
        return true;
    }
  }

  void _next() {
    if (!_stepValid) {
      AppSnackbar.error(context, switch (_step) {
        1 => 'Pick an available time slot to continue.',
        2 => 'Please complete your details to continue.',
        _ => 'Select a service to continue.',
      });
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Pick a service date',
    );
    if (picked != null) {
      setState(() => _date = picked);
      // A different weekday can have different hours, so re-offer the slots.
      _selectFirstSlot();
    }
  }

  Future<void> _submit() async {
    final slot = _slotMinutes;
    if (slot == null) return;

    setState(() => _submitting = true);
    try {
      final booking = await _bookingService.createBooking(
        serviceId: _selectedService!.id,
        // The chosen day and slot are one wall-clock start; the API derives
        // the end from the service duration.
        scheduledDate: BookingSlots.at(_date, slot),
        notes: _notesController.text.trim(),
        paymentMethod: _paymentMethod,
        serviceAddressDetails: _address.toDoorJson(),
        contactPhone: _phoneController.text.trim(),
        idempotencyKey: _idempotencyKey,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      context.pushReplacement('/booking-confirmation', extra: booking);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // The API refuses a taken window, a paused provider or a time outside
      // the published hours — each comes back as a message worth reading.
      AppSnackbar.error(context, apiErrorMessage(e, 'Unable to create this booking.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingState());
    if (_provider == null || _services.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book a Service')),
        body: EmptyState(
          icon: AppIcons.design_services_outlined,
          title: _provider == null ? 'Provider unavailable' : 'No bookable services',
          message: _provider == null
              ? 'This provider could not be loaded. Please try again later.'
              : 'This provider has no approved services to book right now.',
          actionLabel: 'Go back',
          onAction: () => context.pop(),
        ),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Book a Service')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSizes.md),
            _WizardStepper(current: _step, names: const ['Service', 'Schedule', 'Details', 'Confirm'])
                .animate().fadeIn(duration: 300.ms),
            const SizedBox(height: AppSizes.md),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppAnimations.md,
                switchInCurve: AppAnimations.defaultCurve,
                switchOutCurve: AppAnimations.defaultCurve,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, 0, AppSizes.pageHPad, AppSizes.xl),
                  child: _buildStep(context, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.sm, AppSizes.pageHPad, AppSizes.lg),
          child: Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: OutlinedAppButton(
                    label: 'Back',
                    icon: AppIcons.arrow_back_rounded,
                    onPressed: _submitting ? null : () => setState(() => _step--),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
              ],
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: _step == 3 ? 'Confirm booking' : 'Continue',
                  icon: _step == 3 ? AppIcons.check_rounded : AppIcons.arrow_forward_rounded,
                  isLoading: _submitting,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, bool isDark) {
    switch (_step) {
      case 0:
        return _stepService(context, isDark);
      case 1:
        return _stepSchedule(context, isDark);
      case 2:
        return _stepDetails(context, isDark);
      default:
        return _stepConfirm(context, isDark);
    }
  }

  // ── Step 1: choose a service ──
  Widget _stepService(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose a service', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text('Pick the exact service ${_provider!.user.firstName} will provide.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSizes.md),
        for (var i = 0; i < _services.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: _RadioCard(
              selected: _selectedService?.id == _services[i].id,
              title: _services[i].title,
              subtitle: _services[i].duration,
              category: _provider!.categoryName,
              price: _services[i].price,
              onTap: () => _selectService(_services[i]),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 + i * 60), duration: 300.ms)
                .slideY(begin: 0.05, end: 0),
          ),
      ],
    );
  }

  // ── Step 2: schedule ──
  Widget _stepSchedule(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When do you need it?', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text('Pick a date and a time slot that works for you.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSizes.lg),
        SchedulePicker(
          availability: _provider!.availability,
          providerName: _provider!.user.firstName,
          date: _date,
          selectedSlot: _slotMinutes,
          durationMinutes: _selectedService?.durationMinutes ?? 60,
          onPickDate: _pickDate,
          onSlotSelected: (slot) => setState(() => _slotMinutes = slot),
        ),
      ],
    );
  }

  // ── Step 3: details & payment ──
  Widget _stepDetails(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your details', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text('Where should ${_provider!.user.firstName} go, and how will you pay?', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSizes.lg),
        AppTextField(
          label: 'Phone number',
          hint: '09XX XXX XXXX',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: AppIcons.phone_outlined,
          validator: Validators.phone,
        ),
        const SizedBox(height: AppSizes.lg),
        Text('Service address', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSizes.md),
        PhAddressPicker(
          initial: _address,
          onChanged: (address) => setState(() => _address = address),
        ),
        const SizedBox(height: AppSizes.lg),
        AppTextField(
          label: 'Notes (optional)',
          hint: 'Describe the issue or any special instructions…',
          controller: _notesController,
          maxLines: 3,
        ),
        const SizedBox(height: AppSizes.xl),
        Text('Payment method', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Choose how you want to pay the provider. Nothing is charged here — '
          'SkillServe never holds your money, so you pay the provider directly '
          'and they confirm it.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSizes.md),
        for (var i = 0; i < BookingModel.paymentMethods.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: _MethodTile(
              selected: _paymentMethod == BookingModel.paymentMethods[i].$1,
              icon: _paymentIcons[BookingModel.paymentMethods[i].$1] ?? AppIcons.payments_outlined,
              label: BookingModel.paymentMethods[i].$2,
              subtitle: _paymentBlurbs[BookingModel.paymentMethods[i].$1] ?? '',
              onTap: () => setState(() => _paymentMethod = BookingModel.paymentMethods[i].$1),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 150 + i * 50), duration: 300.ms)
                .slideY(begin: 0.05, end: 0),
          ),
      ],
    );
  }

  // ── Step 4: confirm ──
  Widget _stepConfirm(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your booking', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text('Double-check everything before confirming.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSizes.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6), width: 0.8),
            boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
          ),
          child: Column(
            children: [
              _summaryRow(AppIcons.handyman_outlined, 'Provider', _provider!.user.fullName),
              _summaryRow(AppIcons.design_services_outlined, 'Service', _selectedService!.title),
              _summaryRow(AppIcons.schedule_rounded, 'Duration', _selectedService!.duration),
              _summaryRow(AppIcons.calendar_today_rounded, 'Schedule',
                  '${Formatters.dateShort(_date)} · ${BookingSlots.label(_slotMinutes!)}'),
              _summaryRow(AppIcons.person_outline_rounded, 'Client', _clientName),
              _summaryRow(AppIcons.phone_outlined, 'Phone', _phoneController.text.trim()),
              _summaryRow(AppIcons.location_on_outlined, 'Address', _address.formatted),
              _summaryRow(AppIcons.account_balance_wallet_rounded, 'Payment',
                  BookingModel.paymentMethodLabel(_paymentMethod)),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        // Total bar — ink/navy with mono total
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.onDark(AppTextStyles.titleMedium)),
              Text(
                Formatters.peso(_selectedService!.price),
                style: AppTextStyles.monoDisplay.copyWith(color: AppColors.secondaryLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(AppIconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AppIcon(icon, size: 16, color: context.textMutedColor),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Stepper: numbered brass circles with connecting lines ───
class _WizardStepper extends StatelessWidget {
  final int current;
  final List<String> names;

  const _WizardStepper({required this.current, required this.names});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad),
      child: Row(
        children: [
          for (var i = 0; i < names.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: i <= current ? context.accentInk : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppAnimations.md,
                  curve: AppAnimations.defaultCurve,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < current
                        ? AppColors.secondary
                        : (i == current ? AppColors.secondary : (Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceAltDark : AppColors.surfaceAlt)),
                    border: i == current
                        ? Border.all(color: AppColors.secondaryLight, width: 2)
                        : Border.all(color: i < current ? AppColors.secondary : AppColors.neutral200, width: 1.2),
                    boxShadow: i == current
                        ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Center(
                    child: i < current
                        ? const AppIcon(AppIcons.check_rounded, size: 16, color: AppColors.primary)
                        : Text(
                            '${i + 1}',
                            style: AppTextStyles.label.copyWith(
                              color: i == current ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? AppColors.textMutedDark : AppColors.textMuted),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 44,
                  child: Text(
                    names[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: i == current ? context.accentInk : (Theme.of(context).brightness == Brightness.dark ? AppColors.textMutedDark : AppColors.textMuted),
                      fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// ─── Radio-style service card ───
class _RadioCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final String category;
  final double price;
  final VoidCallback onTap;

  const _RadioCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.md,
        curve: AppAnimations.defaultCurve,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary.withValues(alpha: 0.06) : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: selected ? context.accentInk : (isDark ? AppColors.lineDark : AppColors.line),
            width: selected ? 1.6 : 0.8,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
              : AppSizes.shadowFor(context, level: ShadowLevel.sm),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppAnimations.md,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.secondary : Colors.transparent,
                border: Border.all(color: selected ? AppColors.secondary : AppColors.neutral300, width: 1.6),
              ),
              child: selected ? const AppIcon(AppIcons.check_rounded, size: 13, color: AppColors.primary) : null,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text('$category · $subtitle', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              Formatters.peso(price),
              style: AppTextStyles.monoMd.copyWith(color: context.accentInk, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Payment method tile ───
class _MethodTile extends StatelessWidget {
  final bool selected;
  final AppIconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodTile({required this.selected, required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.md,
        curve: AppAnimations.defaultCurve,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary.withValues(alpha: 0.06) : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: selected ? context.accentInk : Colors.transparent, width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: selected ? AppColors.secondary : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: AppIcon(icon, size: 17, color: selected ? AppColors.primary : AppColors.neutral400),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.titleMedium),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            AppIcon(
              selected ? AppIcons.radio_button_checked_rounded : AppIcons.radio_button_off_rounded,
              size: 19,
              color: selected ? context.accentInk : context.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }
}
