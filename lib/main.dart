import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart'; // YENİ: Firebase importu

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
  // 1. Flutter'ın çizim motorunu başlatıyoruz
  WidgetsFlutterBinding.ensureInitialized();

  // 2. YENİ: Firebase Başlatma (Kendi SDK şifrelerinizi buraya yapıştırın)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAAfFBFWu6DBLChKVZ30opP4L7z2vra1dA",
      appId: "1:181125991671:web:fcf82bea37442181c597f2",
      messagingSenderId: "181125991671",
      projectId: "benim-kulturum",
    ),
  );

  // 3. Hive yerel veritabanını başlatıyoruz (Sadece favoriler ve lokal ayarlar için kalacak)
  await Hive.initFlutter();
  await Hive.openBox('favoritesBox');   // Favori ID'lerini tutacak
  await Hive.openBox('reportsBox');     // Gönderilen sorun bildirimlerini tutacak
  await Hive.openBox('userBox');        // Giriş yapan kullanıcının bilgilerini tutacak
  await Hive.openBox('campusDataBox');  // Admin panelini Phase 2'de düzeltene kadar çökmemesi için geçici olarak açık bırakıyoruz.

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
          builder: (context, state) => LoginScreen(),        ),
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