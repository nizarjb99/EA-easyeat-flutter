import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '_auth/login_screen.dart';
import '_common/navigation_screen.dart'; // Import the new main navigation screen

class DashboardRouterScreen extends StatelessWidget {
  const DashboardRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // If logged in, navigate to the MainNavigationScreen which handles
    // both customer and employee specific navigation via the bottom bar.
    return MainNavigationScreen(); // Removed const
  }
}
