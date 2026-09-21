import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/support_controller.dart';
import '../models/support_ticket_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/constants/app_icons.dart';

/// Raise a new support ticket.
class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  TicketCategory _category = TicketCategory.general;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _subjectController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final support = context.read<SupportController>();
    final ticket = await support.createTicket(
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
    );
    if (!mounted) return;

    if (ticket == null) {
      AppSnackbar.error(context, support.errorMessage ?? 'Unable to create this ticket.');
      return;
    }
    AppSnackbar.success(context, 'Ticket ${ticket.ticketNumber} created.');
    context.pushReplacement('/support/tickets/${ticket.id}');
  }

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportController>();

    return Scaffold(
      appBar: AppBar(title: const Text('New Ticket')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How can we help?', style: AppTextStyles.displayMedium)
                  .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 6),
              Text(
                'Tell us what you need and our support team will reply in this ticket.',
                style: AppTextStyles.bodyLarge,
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),

              Text('What is it about?', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in TicketCategory.values)
                    ChoiceChip(
                      label: Text(category.label),
                      selected: _category == category,
                      selectedColor: AppColors.secondary,
                      showCheckmark: false,
                      labelStyle: AppTextStyles.label.copyWith(
                        color: _category == category ? AppColors.primary : null,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _category = category),
                    ),
                ],
              ).animate().fadeIn(delay: 180.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),

              AppTextField(
                label: 'Subject',
                hint: 'A one-line summary',
                controller: _subjectController,
                prefixIcon: AppIcons.edit_outlined,
                maxLength: 160,
                onChanged: (_) => setState(() {}),
              ).animate().fadeIn(delay: 240.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Details',
                hint: 'What happened, and what would you like us to do?',
                controller: _descriptionController,
                maxLines: 6,
                maxLength: 10000,
                onChanged: (_) => setState(() {}),
              ).animate().fadeIn(delay: 300.ms, duration: 350.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSizes.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: PrimaryButton(
            label: 'Create ticket',
            icon: AppIcons.send_rounded,
            isLoading: support.isSubmitting,
            onPressed: _canSubmit && !support.isSubmitting ? _submit : null,
          ),
        ),
      ),
    );
  }
}
