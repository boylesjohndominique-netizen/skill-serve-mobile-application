import 'package:flutter/material.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/age_requirement.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';

/// The professional details a provider sign-up needs, shared by the email
/// and the Google sign-up forms so both create the same provider profile.
///
/// The parent owns the controllers and only shows this block when the
/// provider role is selected; `specialization` is the one required field
/// (it mirrors the backend's `required_if:role,provider`).
class ProviderDetailsFields extends StatelessWidget {
  final TextEditingController businessName;
  final TextEditingController specialization;
  final TextEditingController experienceYears;
  final TextEditingController bio;

  /// The birthday entered on the form, which caps the years of experience.
  final ValueGetter<DateTime?> birthdate;

  /// False while a submission is in flight.
  final bool enabled;

  const ProviderDetailsFields({
    super.key,
    required this.businessName,
    required this.specialization,
    required this.experienceYears,
    required this.bio,
    required this.birthdate,
    this.enabled = true,
  });

  /// Years of experience typed into [experienceYears], clamped to the range
  /// the API accepts. Blank means zero.
  static int parseExperience(String value) {
    final years = int.tryParse(value.trim()) ?? 0;
    return years.clamp(0, 80);
  }

  /// At most the age minus 16: 2 years at 18, 3 at 19, and so on.
  String? _validateExperience(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final years = int.tryParse(value.trim());
    if (years == null) return 'Enter a number of years';
    final max = AgeRequirement.maxExperienceYears(birthdate());
    if (years < 0 || years > max) return 'At your age, enter between 0 and $max years';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your services', style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Clients see this on your profile. You can refine it later during verification.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSizes.lg),
        AppTextField(
          label: 'Specialization',
          hint: 'e.g. Plumbing, Aircon repair',
          controller: specialization,
          prefixIcon: AppIcons.handyman_rounded,
          validator: (v) => Validators.required(v, field: 'Specialization'),
          enabled: enabled,
        ),
        const SizedBox(height: AppSizes.lg),
        AppTextField(
          label: 'Business name (optional)',
          hint: 'e.g. Dela Cruz Home Services',
          controller: businessName,
          enabled: enabled,
        ),
        const SizedBox(height: AppSizes.lg),
        AppTextField(
          label: 'Years of experience (optional)',
          hint: '0',
          controller: experienceYears,
          keyboardType: TextInputType.number,
          validator: _validateExperience,
          enabled: enabled,
        ),
        const SizedBox(height: AppSizes.lg),
        AppTextField(
          label: 'Short bio (optional)',
          hint: 'Tell clients what you do best.',
          controller: bio,
          maxLines: 3,
          enabled: enabled,
        ),
      ],
    );
  }
}
