import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../_employee/home_employee_screen.dart';
import 'discover_screen.dart';
import 'points_wallet_screen.dart';
import '../_customer/qr_code_screen.dart';
import 'profile_screen.dart';
import '../_customer/home_customer_screen.dart'; // Import the new home customer screen

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Screens for employees
  final List<Widget> _employeeScreens = [
    const HomeEmployeeScreen(),
    const DiscoverScreen(), // Placeholder for now
    const ProfileScreen(),
  ];

  // Screens for customers
  final List<Widget> _customerScreens = [
    const HomeCustomerScreen(), // Home for customers
    const DiscoverScreen(),
    const PointsWalletScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isEmployee = authProvider.isEmployee;

    final List<BottomNavigationBarItem> employeeNavItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    final List<BottomNavigationBarItem> customerNavItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'), // Changed to Home
      const BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
      const BottomNavigationBarItem(icon: Icon(Icons.wallet_giftcard), label: 'Points'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    return Scaffold(
      body: isEmployee
          ? _employeeScreens[_selectedIndex]
          : _customerScreens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: isEmployee ? employeeNavItems : customerNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
      ),
    );
  }
}
