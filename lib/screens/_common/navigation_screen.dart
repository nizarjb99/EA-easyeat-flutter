import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../_employee/home_employee_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';
import 'popup_chat_screen.dart';
import '../_customer/home_customer_screen.dart';
import '../_customer/points_wallet_screen.dart';
import '../../features/accessibility/accessibility_floating_button.dart';
import '../../features/accessibility/accessibility_widgets.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;



  void _onItemTapped(int index, bool isEmployee) {
    if (isEmployee) {
      // Employee:
      // 0 -> Home
      // 1 -> Discover
      // 2 -> Xat popup
      // 3 -> Profile
      if (index == 2) {
        _openChatPopup();
        return;
      }

      setState(() {
        _selectedIndex = index == 3 ? 2 : index;
      });

      return;
    }

    // Customer:
    // 0 -> Home
    // 1 -> Discover
    // 2 -> Points
    // 3 -> Xat popup
    // 4 -> Profile
    if (index == 3) {
      _openChatPopup();
      return;
    }

    setState(() {
      _selectedIndex = index == 4 ? 3 : index;
    });
  }

  void _openChatPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return const PopupChatScreen();
      },
    );
  }

  int _getEmployeeBottomIndex() {
    if (_selectedIndex >= 2) {
      return 3;
    }

    return _selectedIndex;
  }

  int _getCustomerBottomIndex() {
    if (_selectedIndex >= 3) {
      return 4;
    }

    return _selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isEmployee = authProvider.isEmployee;
    final bool isStaff = authProvider.isStaff;

    final localeKey = Key(context.locale.toString());

    // We define screens inside build so they recreate and pick up locale changes
    final List<Widget> employeeScreens = [
      HomeEmployeeScreen(key: localeKey),
      DiscoverScreen(key: localeKey),
      ProfileScreen(key: localeKey),
    ];

    final List<Widget> customerScreens = [
      HomeCustomerScreen(key: localeKey),
      DiscoverScreen(key: localeKey),
      PointsWalletScreen(key: localeKey),
      ProfileScreen(key: localeKey),
    ];

    if (isStaff) {
      return ProfileScreen(key: localeKey);
    }

    final List<BottomNavigationBarItem> employeeNavItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore),
        label: 'Discover',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Xat',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    final List<BottomNavigationBarItem> customerNavItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore),
        label: 'Discover',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.wallet_giftcard),
        label: 'Points',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Xat',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AccessibilityWrapper(
        child: Stack(
          children: [
            // ── Main page content ──────────────────────────────────────────
            isEmployee
                ? employeeScreens[_selectedIndex]
                : customerScreens[_selectedIndex],

            // ── Accessibility FAB – bottom: 96 keeps it above the nav bar
            //    (nav bar ≈ 60–64 dp + extra 32 dp breathing room)
            const Positioned(
              right: 24,
              bottom: 96,
              child: AccessibilityFloatingButton(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: isEmployee ? employeeNavItems : customerNavItems,
        currentIndex:
            isEmployee ? _getEmployeeBottomIndex() : _getCustomerBottomIndex(),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => _onItemTapped(index, isEmployee),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}