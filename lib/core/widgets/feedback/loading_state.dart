import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Simple full-space loading indicator for screens without a bespoke
/// shimmer skeleton yet.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.secondary),
    );
  }
}
