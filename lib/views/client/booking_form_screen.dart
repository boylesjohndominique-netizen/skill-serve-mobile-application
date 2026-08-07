import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../data/mock/mock_data.dart';
import '../../models/provider_model.dart';
import '../../models/service_model.dart';
import '../../services/booking_service.dart';
import '../../services/service_service.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

const _slots = ['8:00 AM', '9:30 AM', '11:00 AM', '1:30 PM', '3:00 PM', '4:30 PM'];
const _paymentMethods = [
  ('GCash', AppIcons.account_balance_wallet_rounded, 'Pay instantly via GCash'),
  ('Maya', AppIcons.account_balance_wallet_rounded, 'Pay instantly via Maya'),
  ('Cash on hand', AppIcons.payments_outlined, 'Pay when the job is done'),
  ('Card', AppIcons.credit_card_rounded, 'Pay with a debit / credit card'),
];

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
  final _nameController = TextEditingController(text: MockData.currentClient.fullName);
  final _phoneController = TextEditingController(text: MockData.currentClient.phone);
  final _addressController = TextEditingController(text: MockData.currentClient.address);
  final _notesController = TextEditingController();

  ProviderModel? _provider;
  List<ServiceModel> _services = [];
  bool _loading = true;

  int _step = 0;
  ServiceModel? _selectedService;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _slot = _slots[0];
  String _paymentMethod = 'Cash on hand';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = await ServiceService().getProviderById(widget.providerId);
    var services = await ServiceService().getServicesForProvider(widget.providerId);
    // Fall back to a derived single service when the provider has none on file.
    if (services.isEmpty) {
      services = [
        ServiceModel(
          id: 'SV-${widget.providerId}',
          providerId: widget.providerId,
          categoryId: '1',
          title: '${provider.categoryName} Service',
          description: provider.bio,
          price: provider.startingPrice ?? 500,
          duration: '2 hours',
          coverImage: '',
        ),
      ];
    }
    if (mounted) {
      setState(() {
        _provider = provider;
        _services = services;
        _selectedService = services.first;
        _loading = false;
      });
    }
  }

  bool get _stepValid {
    switch (_step) {
      case 0:
        return _selectedService != null;
      case 1:
        return true; // date + slot always selected by default
      case 2:
        return _nameController.text.trim().isNotEmpty &&
            Validators.phone(_phoneController.text) == null &&
            _addressController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    if (!_stepValid) {
      AppSnackbar.error(context, _step == 2 ? 'Please complete your details to continue.' : 'Select a service to continue.');
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
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final booking = await _bookingService.createBooking(
      providerId: widget.providerId,
      serviceId: _selectedService!.id,
      serviceTitle: _selectedService!.title,
      amount: _selectedService!.price,
      date: _date,
      schedule: _slot,
      address: _addressController.text.trim(),
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      clientName: _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    context.pushReplacement('/booking-confirmation', extra: booking);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _provider == null) return const Scaffold(body: LoadingState());
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
              onTap: () => setState(() => _selectedService = _services[i]),
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
        Text('Date', style: AppTextStyles.titleMedium),
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
                const AppIcon(AppIcons.calendar_today_rounded, size: 18, color: AppColors.secondary),
                const SizedBox(width: AppSizes.sm),
                Text(Formatters.dateShort(_date), style: AppTextStyles.bodyLarge),
                const Spacer(),
                const AppIcon(AppIcons.chevron_right_rounded, size: 18, color: AppColors.neutral300),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xl),
        Text('Available time slots', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _slots.length; i++)
              ChoiceChip(
                label: Text(_slots[i]),
                selected: _slot == _slots[i],
                selectedColor: AppColors.secondary,
                labelStyle: AppTextStyles.label.copyWith(
                  color: _slot == _slots[i] ? AppColors.primary : null,
                  fontWeight: FontWeight.w600,
                ),
                showCheckmark: false,
                onSelected: (_) => setState(() => _slot = _slots[i]),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 150 + i * 40), duration: 300.ms)
                  .slideX(begin: 0.08, end: 0),
          ],
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
        AppTextField(label: 'Full name', hint: 'Juan Dela Cruz', controller: _nameController, prefixIcon: AppIcons.person_outline_rounded),
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
        AppTextField(
          label: 'Service address',
          hint: 'Where should the provider go?',
          controller: _addressController,
          prefixIcon: AppIcons.location_on_outlined,
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
        Text('Choose how you want to pay for this booking.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSizes.md),
        for (var i = 0; i < _paymentMethods.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: _MethodTile(
              selected: _paymentMethod == _paymentMethods[i].$1,
              icon: _paymentMethods[i].$2,
              label: _paymentMethods[i].$1,
              subtitle: _paymentMethods[i].$3,
              onTap: () => setState(() => _paymentMethod = _paymentMethods[i].$1),
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
              _summaryRow(AppIcons.calendar_today_rounded, 'Schedule', '${Formatters.dateShort(_date)} · $_slot'),
              _summaryRow(AppIcons.person_outline_rounded, 'Client', _nameController.text.trim()),
              _summaryRow(AppIcons.phone_outlined, 'Phone', _phoneController.text.trim()),
              _summaryRow(AppIcons.location_on_outlined, 'Address', _addressController.text.trim()),
              _summaryRow(AppIcons.account_balance_wallet_rounded, 'Payment', _paymentMethod),
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
          AppIcon(icon, size: 16, color: AppColors.neutral300),
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
                    color: i <= current ? AppColors.secondary : AppColors.neutral100,
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
                      color: i == current ? AppColors.secondary : (Theme.of(context).brightness == Brightness.dark ? AppColors.textMutedDark : AppColors.textMuted),
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
            color: selected ? AppColors.secondary : (isDark ? AppColors.lineDark : AppColors.line),
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
              style: AppTextStyles.monoMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
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
          border: Border.all(color: selected ? AppColors.secondary : Colors.transparent, width: 1.4),
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
              color: selected ? AppColors.secondary : AppColors.neutral300,
            ),
          ],
        ),
      ),
    );
  }
}
