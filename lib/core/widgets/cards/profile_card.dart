import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../models/user_model.dart';

/// Header card showing avatar, name, and role — used at the top of Profile
/// / Settings screens for both Client and Provider.
class ProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onEdit;
  final Widget? trailingBadge;

  const ProfileCard({super.key, required this.user, this.onEdit, this.trailingBadge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.secondary,
            child: Text(
              user.initials,
              style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: AppTextStyles.onDark(AppTextStyles.titleLarge)),
                const SizedBox(height: 2),
                Text(user.email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
                if (trailingBadge != null) ...[const SizedBox(height: 8), trailingBadge!],
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }
}
