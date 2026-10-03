import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../locations/models/ph_address.dart';
import '../../locations/services/location_service.dart';
import '../../locations/widgets/ph_address_picker.dart';
import '../controllers/identity_controller.dart';
import '../models/scanned_national_id.dart';
import '../../../core/theme/app_palette.dart';

/// The sign-up fields that come from the National ID, pre-filled from the
/// scan and corrected by the user: names, card number, birthday and the
/// structured address. Shared by email and Google sign-up.
class SignUpIdentityForm {
  final givenNames = TextEditingController();
  final middleName = TextEditingController();
  final lastName = TextEditingController();
  final cardNumber = TextEditingController();
  DateTime? birthdate;
  PhAddress address = PhAddress.empty;
  String? _suffix;
  String? _sex;

  /// Fills the fields from a scan; [matched] is the printed address already
  /// resolved to picker selections.
  void fill(ScannedNationalId id, PhAddress matched) {
    givenNames.text = id.givenNames ?? '';
    middleName.text = id.middleName ?? '';
    lastName.text = id.lastName ?? '';
    cardNumber.text = id.formattedCardNumber ?? '';
    birthdate = id.birthdate;
    address = matched;
    _suffix = id.suffix;
    _sex = id.sex;
  }

  /// Fills the fields from a scan, first resolving the printed address to
  /// picker selections. An address the server cannot place is simply left
  /// for the user to pick.
  Future<void> fillFromScan(ScannedNationalId id, {LocationService? locations}) async {
    var matched = PhAddress.empty;
    final printed = id.address;
    if (printed != null && printed.trim().isNotEmpty) {
      try {
        matched = await (locations ?? LocationService()).match(printed);
      } catch (_) {
        // Offline or unmatched: the picker starts empty instead.
      }
    }
    fill(id, matched);
  }

  String get _cardDigits => cardNumber.text.replaceAll(RegExp(r'\D'), '');

  /// The card as the user confirmed it, for the identity review.
  ScannedNationalId get confirmed => ScannedNationalId(
        cardNumber: _cardDigits.isEmpty ? null : _cardDigits,
        givenNames: givenNames.text.trim(),
        middleName: middleName.text.trim().isEmpty ? null : middleName.text.trim(),
        lastName: lastName.text.trim(),
        suffix: _suffix,
        birthdate: birthdate,
        sex: _sex,
        address: address.hasBarangay ? address.formatted : null,
      );

  /// `birthday` and `address_details` for the sign-up request.
  Map<String, dynamic> get signUpDetails => {
        if (birthdate != null) 'birthday': _iso(birthdate!),
        if (address.hasBarangay) 'address_details': address.toDoorJson(),
      };

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void dispose() {
    givenNames.dispose();
    middleName.dispose();
    lastName.dispose();
    cardNumber.dispose();
  }
}

/// The fields for [SignUpIdentityForm], under a note that they were read
/// from the ID and should be checked.
class SignUpIdentityFields extends StatefulWidget {
  const SignUpIdentityFields({super.key, required this.form, required this.onRescan, this.enabled = true});

  final SignUpIdentityForm form;
  final VoidCallback onRescan;
  final bool enabled;

  @override
  State<SignUpIdentityFields> createState() => _SignUpIdentityFieldsState();
}

class _SignUpIdentityFieldsState extends State<SignUpIdentityFields> {
  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final enabled = widget.enabled;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppColors.secondaryDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Filled in from your National ID. Check every field — a camera can misread a letter.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryDeep),
                ),
              ),
              TextButton(
                onPressed: enabled ? widget.onRescan : null,
                // On the pale lime panel in both modes, so always the dark olive.
                style: TextButton.styleFrom(foregroundColor: AppColors.secondaryInk),
                child: const Text('Scan again'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(label: 'Given name(s)', hint: 'Juan', controller: form.givenNames, validator: Validators.required, enabled: enabled),
        const SizedBox(height: 12),
        AppTextField(label: 'Middle name (optional)', hint: 'Santos', controller: form.middleName, enabled: enabled),
        const SizedBox(height: 12),
        AppTextField(label: 'Last name', hint: 'Dela Cruz', controller: form.lastName, validator: Validators.required, enabled: enabled),
        const SizedBox(height: 12),
        AppTextField(
          label: 'PhilSys card number',
          hint: '1234-5678-9012-3456',
          controller: form.cardNumber,
          keyboardType: TextInputType.number,
          enabled: enabled,
          validator: (value) {
            final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
            if (digits.isEmpty) return 'Enter your National ID number.';
            if (digits.length != 16) return 'The card number is 16 digits.';
            return null;
          },
        ),
        const SizedBox(height: 12),
        FormField<DateTime>(
          initialValue: form.birthdate,
          validator: (_) => form.birthdate == null ? 'Enter your date of birth.' : null,
          builder: (field) => InkWell(
            onTap: !enabled
                ? null
                : () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: form.birthdate ?? DateTime(now.year - 20),
                      firstDate: DateTime(now.year - 120),
                      lastDate: now,
                    );
                    if (picked != null) {
                      setState(() => form.birthdate = picked);
                      field.didChange(picked);
                    }
                  },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date of birth',
                border: const OutlineInputBorder(),
                errorText: field.errorText,
              ),
              child: Text(
                form.birthdate == null
                    ? 'Select your date of birth'
                    : MaterialLocalizations.of(context).formatMediumDate(form.birthdate!),
                style: TextStyle(color: form.birthdate == null ? context.textSecondaryColor : null),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Address', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        PhAddressPicker(
          initial: form.address,
          enabled: enabled,
          onChanged: (address) => form.address = address,
        ),
      ],
    );
  }
}

/// Right after the account is created (email code confirmed, or Google
/// sign-up finished): sends the card scanned at sign-up for review and
/// returns where to go next. When nothing complete was scanned, or the API
/// refused it, the National ID screen takes over, pre-filled from the scan.
Future<String> submitScannedIdAndRoute(IdentityController identity, {required bool isProvider}) async {
  final home = isProvider ? '/provider-onboarding' : '/client';
  if (await identity.submitScanned()) return home;
  return isProvider ? '/identity-verification?next=${Uri.encodeComponent(home)}' : '/identity-verification';
}
