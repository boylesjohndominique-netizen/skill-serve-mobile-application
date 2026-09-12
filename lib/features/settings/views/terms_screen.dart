import 'package:flutter/material.dart';
import 'static_info_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaticInfoScreen(
      title: 'Terms & Conditions',
      sections: [
        StaticSection(
          heading: '1. Acceptance of terms',
          body: 'By creating an account or using SkillServe, clients and providers agree to abide by these '
              'terms, including platform conduct guidelines and dispute resolution processes.',
        ),
        StaticSection(
          heading: '2. Bookings',
          body: 'Bookings are agreements directly between the client and provider. SkillServe facilitates the '
              'connection but is not a party to the underlying service agreement.',
        ),
        StaticSection(
          heading: '3. Verification',
          body: 'Providers must submit valid identification and, where applicable, certificates for admin '
              'review before their profile becomes publicly bookable.',
        ),
        StaticSection(
          heading: '4. Account suspension',
          body: 'SkillServe reserves the right to suspend accounts that violate platform guidelines, including '
              'fraudulent activity, harassment, or repeated no-shows.',
        ),
      ],
    );
  }
}
