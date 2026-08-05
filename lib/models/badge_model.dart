import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

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

  IconData get icon {
    switch (key) {
      case 'top_rated':
        return Icons.star_rounded;
      case 'rising_star':
        return Icons.trending_up_rounded;
      case 'veteran':
        return Icons.military_tech_rounded;
      case 'verified_pro':
        return Icons.verified_rounded;
      case 'community_favorite':
        return Icons.favorite_rounded;
      default:
        return Icons.workspace_premium_rounded;
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
