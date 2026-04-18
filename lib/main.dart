import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Theme & Providers
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';

// Screens (To be generated in next steps)
import 'package:benim_kulturum_v1/screens/splash_screen.dart';
import 'package:benim_kulturum_v1/screens/welcome_screen.dart';
import 'package:benim_kulturum_v1/screens/login_screen.dart';
import 'package:benim_kulturum_v1/screens/main_screen.dart';
import 'package:benim_kulturum_v1/screens/admin_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
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

    return MaterialApp.router(
      title: 'Benim Kültürüm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}