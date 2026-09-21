import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../services/platform_service.dart';
import 'static_info_screen.dart';

/// A platform policy (M 14.4): the text administrators publish in System
/// Settings → Platform policies. Until one is published, or while offline,
/// the bundled [fallback] is shown instead.
class PolicyScreen extends StatefulWidget {
  final String title;

  /// `terms_of_service`, `privacy_policy` or `community_guidelines`.
  final String policyKey;
  final List<StaticSection> fallback;

  const PolicyScreen({super.key, required this.title, required this.policyKey, required this.fallback});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  late final Future<String> _published = _load();

  Future<String> _load() async {
    try {
      return (await PlatformService().get()).policy(widget.policyKey).trim();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _published,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final text = snapshot.data ?? '';
        if (text.isEmpty) return StaticInfoScreen(title: widget.title, sections: widget.fallback);

        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.pageHPad),
              children: [
                // Paragraphs as the administrator wrote them.
                for (final paragraph in text.split(RegExp(r'\n\s*\n'))) ...[
                  SelectableText(paragraph.trim(), style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSizes.lg),
                ],
                Text('Published by SkillServe administrators.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400)),
              ],
            ),
          ),
        );
      },
    );
  }
}
