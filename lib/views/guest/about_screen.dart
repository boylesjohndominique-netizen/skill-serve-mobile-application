import 'package:flutter/material.dart';
import 'static_info_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaticInfoScreen(
      title: 'About SkillLink',
      sections: [
        StaticSection(
          body: 'SkillLink bridges service accessibility and talent visibility by connecting households across '
              'Cebu, Bohol, and Dumaguete with verified local service professionals — from plumbers and '
              'electricians to tutors, designers, and photographers.',
        ),
        StaticSection(
          heading: 'Our mission',
          body: 'To make it effortless for clients to find trustworthy talent, and for skilled providers to '
              'build a visible, thriving service business.',
        ),
        StaticSection(
          heading: 'Why SkillLink',
          body: 'Every provider on the platform is ID-verified and rated by real clients, so bookings come '
              'with built-in accountability on both sides.',
        ),
      ],
    );
  }
}
