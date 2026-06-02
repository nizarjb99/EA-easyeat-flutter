import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/restaurant_provider.dart';

import 'screens/_auth/landing_screen.dart';
import 'screens/_auth/legal_notice_screen.dart';
import 'screens/_auth/login_screen.dart';
import 'screens/_auth/register_screen.dart';
import 'screens/_common/notification_screen.dart';
import 'screens/app_entry_point.dart';
import 'screens/_employee/add_visit_screen.dart';
import 'screens/_employee/exchange_confirmation_screen.dart';
import 'screens/_employee/exchange_reward_screen.dart';
import 'screens/_employee/visit_confirmation_screen.dart';
import 'utils/styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp();
  }

  final locationProvider = LocationProvider();
  await locationProvider.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es'), Locale('ca')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => RestaurantProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => locationProvider),
          ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
            create: (_, auth, provider) {
              provider!.bindAuth(auth);
              return provider;
            },
          ),
        ],
        child: const EventManagerApp(),
      ),
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
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardRouterScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/add-visit': (context) => const AddVisitScreen(),
        '/visit-confirmation': (context) => const VisitConfirmationScreen(),
        '/aviso-legal': (context) => const LegalNoticePage(),
        '/exchange-reward': (context) => const ExchangeRewardScreen(),
        '/exchange-confirmation': (context) => const ExchangeConfirmationScreen(),
      },
    );
  }
}