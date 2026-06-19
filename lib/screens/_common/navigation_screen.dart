import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/fcm_service.dart';
import '../../services/notification_router.dart';
import '../_employee/home_employee_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';
import 'popup_chat_screen.dart';
import '../_customer/home_customer_screen.dart';
import '../_customer/points_wallet_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  FcmService? _fcmService;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final auth = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    if (!auth.isLoggedIn || !auth.isCustomer) {
      return;
    }

    _fcmService = FcmService();

    await _fcmService!.initialize(
      customerId: auth.id,
      getAccessToken: () => auth.accessToken,
      onNotificationTap: (payload) async {
        if (!mounted) return;
        await NotificationRouter.routeFromPayload(context, payload);
      },
      onForegroundNotification: (notification) {
        notificationProvider.upsertForegroundNotification(notification);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notification.message),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Veure',
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _fcmService?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index, bool isEmployee) {
    if (isEmployee) {
      if (index == 2) {
        _openChatPopup();
        return;
      }
    } else {
      if (index == 3) {
        _openChatPopup();
        return;
      }
    }

    setState(() {
      _selectedIndex = index;
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
    return _selectedIndex;
  }

  int _getCustomerBottomIndex() {
    return _selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isEmployee = authProvider.isEmployee;
    final bool isStaff = authProvider.isStaff;

    final localeKey = Key(context.locale.toString());

    final List<Widget> employeeScreens = [
      HomeEmployeeScreen(key: localeKey),
      DiscoverScreen(key: localeKey),
      const SizedBox(), // chat placeholder
      ProfileScreen(key: localeKey),
    ];

    final List<Widget> customerScreens = [
      HomeCustomerScreen(key: localeKey),
      DiscoverScreen(key: localeKey),
      PointsWalletScreen(key: localeKey),
      const SizedBox(), // chat placeholder
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
      body: isEmployee
          ? employeeScreens[_selectedIndex]
          : customerScreens[_selectedIndex],
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