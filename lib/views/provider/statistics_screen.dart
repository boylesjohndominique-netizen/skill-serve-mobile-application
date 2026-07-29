import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/mock/mock_data.dart';

/// Deeper performance view — completed jobs trend, rating breakdown, and
/// category share. Uses simple bar visualizations (no chart package
/// dependency) so the layout stays lightweight.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = MockData.providers.first;
    final monthly = [4, 7, 5, 9, 6, 8]; // mock completed-jobs-per-month
    final months = ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
    final maxVal = monthly.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Avg. Rating', value: provider.averageRating.toStringAsFixed(1), icon: Icons.star_rounded)),
                const SizedBox(width: AppSizes.md),
                Expanded(child: _StatCard(label: 'Total Jobs', value: '${provider.completedJobs}', icon: Icons.task_alt_rounded)),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Total Reviews', value: '${provider.reviewCount}', icon: Icons.reviews_rounded)),
                const SizedBox(width: AppSizes.md),
                Expanded(child: _StatCard(label: 'Years Active', value: '${provider.yearsExperience}', icon: Icons.timeline_rounded)),
              ],
            ),
            const SizedBox(height: AppSizes.xl),
            Text('Completed Jobs (Last 6 Months)', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.lg),
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusLg), border: Border.all(color: AppColors.line)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (int i = 0; i < monthly.length; i++)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${monthly[i]}', style: AppTextStyles.caption),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: 90 * (monthly[i] / maxVal),
                          decoration: BoxDecoration(
                            color: i == monthly.length - 1 ? AppColors.secondary : AppColors.primary.withValues(alpha: 0.75),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(months[i], style: AppTextStyles.caption),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text('Rating Breakdown', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.md),
            for (final entry in const [(5, 0.68), (4, 0.21), (3, 0.07), (2, 0.03), (1, 0.01)])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Row(
                  children: [
                    Text('${entry.$1}', style: AppTextStyles.label),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, size: 13, color: AppColors.star),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.$2,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceAlt,
                          valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text('${(entry.$2 * 100).toStringAsFixed(0)}%', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusLg), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headlineMedium),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
