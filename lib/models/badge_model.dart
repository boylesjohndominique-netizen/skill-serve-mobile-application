import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';

/// A recognition badge awarded to providers by performance rules
/// (see spec Section 4).
class BadgeModel {
  final String key; // top_rated | rising_star | veteran | verified_pro | community_favorite
  final String title;
  final String criteria; // what the provider must achieve
  final bool earned;
  final double progress; // 0.0–1.0 toward earning (1.0 when earned)
  final String progressLabel; // e.g. "18/20 jobs"

  const BadgeModel({
    required this.key,
    required this.title,
    required this.criteria,
    this.earned = false,
    this.progress = 0,
    this.progressLabel = '',
  });

  AppIconData get icon {
    switch (key) {
      case 'top_rated':
        return AppIcons.star_rounded;
      case 'rising_star':
        return AppIcons.trending_up_rounded;
      case 'veteran':
        return AppIcons.military_tech_rounded;
      case 'verified_pro':
        return AppIcons.verified_rounded;
      case 'community_favorite':
        return AppIcons.favorite_rounded;
      default:
        return AppIcons.workspace_premium_rounded;
    }
  }

  Color get color {
    switch (key) {
      case 'top_rated':
        return AppColors.secondary; // brass
      case 'rising_star':
        return AppColors.info; // blue
      case 'veteran':
        return AppColors.neutral400; // slate
      case 'verified_pro':
        return AppColors.success; // emerald
      case 'community_favorite':
        return AppColors.error; // red
      default:
        return AppColors.secondary;
    }
  }
}
