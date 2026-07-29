import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';

/// Shared template for simple static content pages (About, Terms,
/// Privacy Policy). Features staggered section fade-in.
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
            for (var i = 0; i < sections.length; i++) ...[
              if (sections[i].heading != null) ...[
                Text(sections[i].heading!, style: AppTextStyles.titleLarge)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: i * 100), duration: 350.ms)
                    .slideY(begin: 0.06, end: 0),
                const SizedBox(height: 6),
              ],
              Text(sections[i].body, style: AppTextStyles.bodyLarge)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 50 + i * 100), duration: 350.ms),
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
