import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../services/profile_service.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _firstName = TextEditingController(text: user?.firstName);
    _lastName = TextEditingController(text: user?.lastName);
    _phone = TextEditingController(text: user?.phone);
    _address = TextEditingController(text: user?.address);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    if (auth.currentUser == null) return;
    setState(() => _saving = true);
    final updated = await _profileService.updateProfile(
      auth.currentUser!,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
    );
    auth.updateCurrentUser(updated);
    setState(() => _saving = false);
    if (mounted) {
      AppSnackbar.success(context, 'Profile updated.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary,
                        child: Text(user?.initials ?? '?', style: const TextStyle(color: Colors.white, fontSize: 28)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                          child: const AppIcon(AppIcons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                const SizedBox(height: AppSizes.xl),
                Row(
                  children: [
                    Expanded(child: AppTextField(label: 'First name', controller: _firstName, validator: Validators.required)),
                    const SizedBox(width: AppSizes.md),
                    Expanded(child: AppTextField(label: 'Last name', controller: _lastName, validator: Validators.required)),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Phone number',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: AppIcons.call_outlined,
                  validator: Validators.phone,
                ).animate().fadeIn(delay: 180.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Address',
                  controller: _address,
                  prefixIcon: AppIcons.location_on_outlined,
                  validator: Validators.required,
                ).animate().fadeIn(delay: 260.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.xxl),
                PrimaryButton(label: 'Save changes', isLoading: _saving, onPressed: _save)
                    .animate().fadeIn(delay: 340.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
