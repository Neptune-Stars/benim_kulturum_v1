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

  // YENİ: HomeScreen'e göndereceğimiz sekme değiştirme fonksiyonu
  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ekranları buraya taşıdık ki _switchTab fonksiyonunu HomeScreen'e aktarabilelim
    final List<Widget> screens = [
      HomeScreen(onSwitchTab: _switchTab), // YENİ: Uzaktan kumanda fonksiyonunu verdik!
      const BuildingsScreen(),
      const CafeteriaMenuScreen(),
      const AnnouncementsScreen(),
      const ProfileScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorderColor : AppTheme.borderColor;
    final navBackgroundColor = isDark ? AppTheme.darkCardColor : Colors.white;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _switchTab, // YENİ: Alt barda tıklanınca da aynı fonksiyon çalışır
            type: BottomNavigationBarType.fixed,
            backgroundColor: navBackgroundColor,
            selectedItemColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
            unselectedItemColor: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Anasayfa"),
              BottomNavigationBarItem(icon: Icon(Icons.business_outlined), activeIcon: Icon(Icons.business), label: "Kampüs"),
              BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined), activeIcon: Icon(Icons.restaurant), label: "Yemek"),
              BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign), label: "Duyurular"),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profil"),
            ],
          ),
        ),
      ),
    );
  }
}