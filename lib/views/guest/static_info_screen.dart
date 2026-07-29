import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';

/// Shared template for simple static content pages (About, Terms,
/// Privacy Policy). Content is placeholder copy — replace with the real
/// legal/marketing text before shipping.
class StaticInfoScreen extends StatelessWidget {
  final String title;
  final List<StaticSection> sections;

  const StaticInfoScreen({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            for (final section in sections) ...[
              if (section.heading != null) ...[
                Text(section.heading!, style: AppTextStyles.titleLarge),
                const SizedBox(height: 6),
              ],
              Text(section.body, style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSizes.xl),
            ],
          ],
        ),
      ),
    );
  }
}

class StaticSection {
  final String? heading;
  final String body;
  const StaticSection({this.heading, required this.body});
}
