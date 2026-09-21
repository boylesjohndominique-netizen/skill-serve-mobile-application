import 'package:flutter/material.dart';

import 'policy_screen.dart';
import 'static_info_screen.dart';

/// Community guidelines (M 14.4), as published by administrators.
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyScreen(
      policyKey: 'community_guidelines',
      title: 'Community Guidelines',
      fallback: [
        StaticSection(
          heading: 'Be respectful',
          body: 'Treat clients and providers with courtesy in messages, reviews and in person. Harassment, '
              'discrimination and abusive language are not allowed.',
        ),
        StaticSection(
          heading: 'Be honest',
          body: 'Describe services, prices and experience truthfully. Reviews must reflect a real booking. Fake '
              'accounts, misleading listings and spam are removed.',
        ),
        StaticSection(
          heading: 'Keep your commitments',
          body: 'Show up for confirmed bookings, and cancel early when plans change. Late cancellations can carry '
              'a fee set by the platform.',
        ),
        StaticSection(
          heading: 'Stay safe',
          body: 'Keep conversations and arrangements in the app. Report anything unsafe or suspicious — our team '
              'reviews every report.',
        ),
        StaticSection(
          heading: 'Consequences',
          body: 'Breaking these guidelines can lead to a warning, hidden content, suspension or a ban.',
        ),
      ],
    );
  }
}
