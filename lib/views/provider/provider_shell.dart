import 'package:flutter/material.dart';
import '../../core/widgets/navigation/app_bottom_nav.dart';
import '../client/chat_list_screen.dart';
import 'dashboard_screen.dart';
import 'booking_requests_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';

const _providerNavItems = [
  NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Dashboard'),
  NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Bookings'),
  NavItem(icon: Icons.photo_library_outlined, activeIcon: Icons.photo_library_rounded, label: 'Portfolio'),
  NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages'),
  NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
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
    ProviderPortfolioScreen(embedded: true),
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
