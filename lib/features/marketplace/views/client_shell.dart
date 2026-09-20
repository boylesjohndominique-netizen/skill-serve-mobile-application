import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/navigation/app_bottom_nav.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import '../../booking/views/booking_history_screen.dart';
import '../../messaging/controllers/chat_controller.dart';
import '../../messaging/views/chat_list_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../../../core/constants/app_icons.dart';

const _clientNavItems = [
  NavItem(icon: AppIcons.home_outlined, activeIcon: AppIcons.home_rounded, label: 'Home'),
  NavItem(icon: AppIcons.explore_outlined, activeIcon: AppIcons.explore_rounded, label: 'Explore'),
  NavItem(icon: AppIcons.calendar_today_outlined, activeIcon: AppIcons.calendar_today_rounded, label: 'Bookings'),
  NavItem(icon: AppIcons.chat_bubble_outline_rounded, activeIcon: AppIcons.chat_bubble_rounded, label: 'Messages'),
  NavItem(icon: AppIcons.person_outline_rounded, activeIcon: AppIcons.person_rounded, label: 'Profile'),
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

  /// Nav items with the live unread-message count on the Messages tab.
  List<NavItem> _itemsWithUnreadBadge(BuildContext context) {
    final unread = context.select<ChatController, int>((c) => c.unreadCount);
    return [
      for (var i = 0; i < _clientNavItems.length; i++)
        i == 3 ? _clientNavItems[i].withBadge(unread) : _clientNavItems[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        items: _itemsWithUnreadBadge(context),
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
