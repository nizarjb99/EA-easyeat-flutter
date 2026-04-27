import 'package:flutter/material.dart';

import 'employee_dashboard_screen.dart';
import 'profile_screen.dart';
import 'qr_code_screen.dart';

class EmployeeMainWrapperScreen extends StatefulWidget {
  const EmployeeMainWrapperScreen({super.key});

  @override
  State<EmployeeMainWrapperScreen> createState() => _EmployeeMainWrapperScreenState();
}

class _EmployeeMainWrapperScreenState extends State<EmployeeMainWrapperScreen> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_currentIndex].currentState!.maybePop();
        if (isFirstRouteInCurrentTab && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildOffstageNavigator(0, const EmployeeDashboardScreen()),
            _buildOffstageNavigator(1, const QRCodeScreen()),
            _buildOffstageNavigator(2, const ProfileScreen()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == _currentIndex) {
              _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
            } else {
              setState(() => _currentIndex = index);
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR Code'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildOffstageNavigator(int index, Widget rootWidget) {
    return Offstage(
      offstage: _currentIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => rootWidget),
      ),
    );
  }
}
