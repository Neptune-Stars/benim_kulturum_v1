import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'home_screen.dart';
import 'buildings_screen.dart';
import 'cafeteria_menu_screen.dart';
import 'announcements_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BuildingsScreen(),
    CafeteriaMenuScreen(),
    AnnouncementsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Koyu tema açık mı kontrol ediyoruz
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Temaya göre çizgi ve arkaplan renklerini belirliyoruz
    final borderColor = isDark ? AppTheme.darkBorderColor : AppTheme.borderColor;
    final navBackgroundColor = isDark ? AppTheme.darkCardColor : Colors.white;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: borderColor, width: 1), // Çizgi rengi dinamik oldu
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: navBackgroundColor, // Arkaplan rengi dinamik oldu
          selectedItemColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor, // Seçili ikon rengi
          unselectedItemColor: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted, // Seçilmeyen ikon rengi
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Anasayfa",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_outlined),
              activeIcon: Icon(Icons.business),
              label: "Kampüs", // "Kampüs Rehber" yazısı taşıp taşmadığına göre kısaltılabilir
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_outlined),
              activeIcon: Icon(Icons.restaurant),
              label: "Yemek",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: "Duyurular",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profil",
            ),
          ],
        ),
      ),
    );
  }
}