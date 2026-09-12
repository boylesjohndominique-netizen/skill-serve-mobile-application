import 'package:flutter/material.dart';
import 'static_info_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaticInfoScreen(
      title: 'Privacy Policy',
      sections: [
        StaticSection(
          heading: 'Information we collect',
          body: 'SkillServe collects only the information required to match clients with providers and process '
              'bookings securely — including contact details, booking history, and verification documents.',
        ),
        StaticSection(
          heading: 'How we use your information',
          body: 'Your information is used to facilitate bookings, verify provider identity, and improve the '
              'overall marketplace experience. We do not sell personal data to third parties.',
        ),
        StaticSection(
          heading: 'Your controls',
          body: 'You can review, update, or request deletion of your personal information at any time from '
              'your account settings.',
        ),
      ],
    );
  }
}
