import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../profile/services/profile_service.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/app_avatar.dart';
import '../../../core/constants/app_icons.dart';

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
  String? _selectedPhoto;
  bool _removePhoto = false;

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
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    if (auth.currentUser == null) return;
    setState(() => _saving = true);
    try {
      final updated = await _profileService.updateProfile(
        auth.currentUser!,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        profilePicture: _selectedPhoto,
        clearProfilePicture: _removePhoto,
      );
      auth.updateCurrentUser(updated);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _selectedPhoto = null;
        _removePhoto = false;
      });
      AppSnackbar.success(context, 'Profile updated.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context,
          apiErrorMessage(e, 'Could not save your profile. Please try again.'));
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
                      AppAvatar(
                        initials: user?.initials ?? '?',
                        photoUrl: _removePhoto
                            ? null
                            : _selectedPhoto ?? user?.profilePicture,
                        radius: 44,
                      ),
                      Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle),
                            child: IconButton(
                              tooltip: 'Change profile photo',
                              onPressed: _saving ? null : _pickPhoto,
                              icon: const AppIcon(AppIcons.camera_alt_rounded,
                                  size: 16, color: AppColors.primary),
                            ),
                          )),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).scale(
                    begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                if ((user?.profilePicture != null || _selectedPhoto != null) &&
                    !_removePhoto) ...[
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed:
                          _saving ? null : () => setState(() => _removePhoto = true),
                      icon: const AppIcon(AppIcons.delete_outline_rounded,
                          size: 16),
                      label: const Text('Remove photo'),
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.xl),
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            label: 'First name',
                            controller: _firstName,
                            validator: Validators.required,
                            enabled: !_saving)),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                        child: AppTextField(
                            label: 'Last name',
                            controller: _lastName,
                            validator: Validators.required,
                            enabled: !_saving)),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Phone number',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: AppIcons.call_outlined,
                  validator: Validators.phone,
                  enabled: !_saving,
                )
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Address',
                  controller: _address,
                  prefixIcon: AppIcons.location_on_outlined,
                  validator: Validators.required,
                  enabled: !_saving,
                )
                    .animate()
                    .fadeIn(delay: 260.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.xxl),
                PrimaryButton(
                        label: 'Save changes',
                        isLoading: _saving,
                        onPressed: _save)
                    .animate()
                    .fadeIn(delay: 340.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (photo == null || !mounted) return;
    setState(() {
      _selectedPhoto = photo.path;
      _removePhoto = false;
    });
  }
}
