import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_wrapper_screen.dart';
import 'providers/auth_provider.dart';
import 'utils/styles.dart';

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
      theme: AppStyles.lightTheme, // Start with light for Auth
      darkTheme: AppStyles.darkTheme,
      themeMode: ThemeMode.system,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // If the user is logged in, show the main dashboard
          if (auth.isLoggedIn) {
            return const MainWrapperScreen();
          }
          // Otherwise show the login screen
          return const LoginScreen();
        },
      ),
    );
  }
}
