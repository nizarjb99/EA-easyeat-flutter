import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '_auth/login_screen.dart';
import '_common/navigation_screen.dart';
import 'loading_splash.dart';

class DashboardRouterScreen extends StatelessWidget {
  const DashboardRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // tryRestoreSession() is started in main() before runApp, so _isLoading
    // is already true on frame 1 — LoadingSplash shows with no blank flash.
    if (auth.isLoading) {
      return const LoadingSplash();
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    return MainNavigationScreen();
  }
}
