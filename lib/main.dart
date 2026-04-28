import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'utils/styles.dart';

import 'screens/_auth/landing_screen.dart';
import 'screens/_auth/login_screen.dart';
import 'screens/_auth/register_screen.dart';
import 'screens/app_entry_point.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const EventManagerApp(),
    ),
  );
}

class EventManagerApp extends StatelessWidget {
  const EventManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EasyEat',
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardRouterScreen(),
      },
    );
  }
}
