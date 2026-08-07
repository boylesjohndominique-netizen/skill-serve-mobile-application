import 'package:flutter/material.dart';
import '../../core/widgets/navigation/app_bottom_nav.dart';
import '../client/chat_list_screen.dart';
import 'dashboard_screen.dart';
import 'booking_requests_screen.dart';
import 'my_services_screen.dart';
import 'settings_screen.dart';
import '../../core/constants/app_icons.dart';

const _providerNavItems = [
  NavItem(icon: AppIcons.grid_view_outlined, activeIcon: AppIcons.grid_view_rounded, label: 'Home'),
  NavItem(icon: AppIcons.calendar_today_outlined, activeIcon: AppIcons.calendar_today_rounded, label: 'Bookings'),
  NavItem(icon: AppIcons.design_services_outlined, activeIcon: AppIcons.design_services_rounded, label: 'Services'),
  NavItem(icon: AppIcons.chat_bubble_outline_rounded, activeIcon: AppIcons.chat_bubble_rounded, label: 'Messages'),
  NavItem(icon: AppIcons.person_outline_rounded, activeIcon: AppIcons.person_rounded, label: 'Profile'),
];

/// Bottom-nav shell for the Service Provider persona.
class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  int _index = 0;

  final _screens = const [
    ProviderDashboardScreen(),
    BookingRequestsScreen(embedded: true),
    MyServicesScreen(embedded: true),
    ChatListScreen(),
    ProviderSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        items: _providerNavItems,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
