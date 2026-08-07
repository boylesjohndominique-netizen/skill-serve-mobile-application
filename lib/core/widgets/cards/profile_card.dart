import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../models/user_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/app_avatar.dart';
import '../../../core/constants/app_icons.dart';

/// Header card showing avatar, name, and role — used at the top of Profile
/// / Settings screens for both Client and Provider.
/// Features a subtle gradient shine and avatar border ring.
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.6), width: 2),
            ),
            child: AppAvatar(
              initials: user.initials,
              radius: 28,
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: IconButton(
                onPressed: onEdit,
                icon: const AppIcon(AppIcons.edit_rounded, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
