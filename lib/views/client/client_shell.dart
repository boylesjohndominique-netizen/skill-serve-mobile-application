import 'package:flutter/material.dart';
import '../../core/widgets/navigation/app_bottom_nav.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'booking_history_screen.dart';
import 'chat_list_screen.dart';
import 'settings_screen.dart';

const _clientNavItems = [
  NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
  NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Explore'),
  NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Bookings'),
  NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages'),
  NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
];

/// Bottom-nav shell for the Client persona. Keeps each tab's scroll and
/// state alive via [IndexedStack] instead of rebuilding on every switch.
class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  final _screens = const [
    ClientHomeScreen(),
    ClientSearchScreen(),
    BookingHistoryScreen(embedded: true),
    ChatListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        items: _clientNavItems,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
