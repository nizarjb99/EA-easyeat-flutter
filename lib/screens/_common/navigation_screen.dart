import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../_employee/home_employee_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';
import '../_customer/home_customer_screen.dart';
import '../_customer/points_wallet_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'sidebar.home'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.explore), label: 'sidebar.discover'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'sidebar.profile'.tr()),
    ];

    final List<BottomNavigationBarItem> customerNavItems = [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'sidebar.home'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.explore), label: 'sidebar.discover'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.wallet_giftcard), label: 'sidebar.points'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'sidebar.profile'.tr()),
    ];

    return Scaffold(
      body: isEmployee
          ? employeeScreens[_selectedIndex]
          : customerScreens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: isEmployee ? employeeNavItems : customerNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
