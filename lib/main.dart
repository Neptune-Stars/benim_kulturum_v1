import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart'; // HIVE IMPORTU EKLENDİ

import 'theme/app_theme.dart';

import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/joined_events_provider.dart';
import 'providers/theme_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin_dashboard_screen.dart';

import 'providers/profile_provider.dart';

import 'providers/notification_provider.dart';

void main() async {
  // 1. Flutter'ın çizim motorunu başlatıyoruz (Asenkron işlemler için şart)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Hive yerel veritabanını cihazda başlatıyoruz
  await Hive.initFlutter();

  // 3. İhtiyacımız olan veritabanı kutularını (tablolarını) açıyoruz
  await Hive.openBox('favoritesBox');   // Favori ID'lerini tutacak
  await Hive.openBox('reportsBox');     // Gönderilen sorun bildirimlerini tutacak
  await Hive.openBox('userBox');        // Giriş yapan kullanıcının bilgilerini (Admin mi Öğrenci mi) tutacak
  await Hive.openBox('campusDataBox');  // Binalar, Hocalar, Menüler gibi ana verileri tutacak

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => JoinedEventsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider()..loadProfileImage(),
        ),

      ],
      child: const BenimKulturumApp(),
    ),
  );
}

class BenimKulturumApp extends StatelessWidget {
  const BenimKulturumApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/main',
          builder: (context, state) => const MainScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          title: 'Benim Kültürüm',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: router,
        );
      },
    );
  }
}