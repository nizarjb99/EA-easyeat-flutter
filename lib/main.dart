import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/theme_provider.dart';

import 'screens/_auth/legal_notice_screen.dart';
import 'screens/_common/accessibility/accessibility_controller.dart';
import 'screens/_auth/login_screen.dart';
import 'screens/_auth/register_screen.dart';
import 'screens/_common/notification_screen.dart';
import 'screens/app_entry_point.dart';
import 'screens/loading_splash.dart';
import 'screens/_employee/add_visit_screen.dart';
import 'screens/_employee/exchange_confirmation_screen.dart';
import 'screens/_employee/exchange_reward_screen.dart';
import 'screens/_employee/visit_confirmation_screen.dart';
import 'screens/_customer/restaurant_search_screen.dart';
import 'services/fcm_service.dart' show firebaseMessagingBackgroundHandler;
import 'utils/styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp();

    // Must be registered before any other Firebase call and before runApp.
    // The handler must be a top-level function annotated with
    // @pragma('vm:entry-point') – see fcm_service.dart.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final locationProvider = LocationProvider();
  await locationProvider.initialize();

  // Pre-create AuthProvider and kick off session restore BEFORE runApp.
  // This ensures _isLoading is already true on the very first frame, so
  // DashboardRouterScreen immediately renders LoadingSplash — no blank flash.
  // tryRestoreSession() runs concurrently while the widget tree builds.
  final authProvider = AuthProvider();
  authProvider.tryRestoreSession(); // intentionally not awaited

  // Load saved accessibility settings before the first frame.
  final accessibilityController = AccessibilityController();
  await accessibilityController.loadFromPrefs();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es'), Locale('ca')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          // Hand the pre-created instance to the provider tree so the
          // in-flight tryRestoreSession() notifies the correct listeners.
          ChangeNotifierProvider(create: (_) => authProvider),
          ChangeNotifierProvider(create: (_) => RestaurantProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => locationProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),

          ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
            create: (_) => NotificationProvider(),
            update: (_, auth, notificationProvider) {
              notificationProvider!.bindAuth(auth);
              return notificationProvider;
            },
          ),
          ChangeNotifierProvider<AccessibilityController>(
            create: (_) => accessibilityController,
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
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EasyEat',
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardRouterScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardRouterScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/add-visit': (context) => const AddVisitScreen(),
        '/visit-confirmation': (context) => const VisitConfirmationScreen(),
        '/aviso-legal': (context) => const LegalNoticePage(),
        '/exchange-reward': (context) => const ExchangeRewardScreen(),
        '/exchange-confirmation': (context) => const ExchangeConfirmationScreen(),
        '/search': (context) => const RestaurantSearchScreen(),
      },
    );
  }
}
