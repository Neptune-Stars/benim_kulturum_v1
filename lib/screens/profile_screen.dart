import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_row.dart';
import '../widgets/badge_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import 'report_issue_screen.dart';
import 'favorites_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favCount = context.watch<FavoritesProvider>().favorites.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 48, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    const Text("Öğrenci Adı", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("20210001234", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 12),
                    AppBadge(label: "3. Sınıf", backgroundColor: Colors.white.withOpacity(0.2), textColor: Colors.white),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  children: [
                                    Text(favCount.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                    const SizedBox(height: 4),
                                    const Text("Favori", style: TextStyle(color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  const Text("12", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                  const SizedBox(height: 4),
                                  const Text("Ziyaret Edilen", style: TextStyle(color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ayarlar
                    const Text("Ayarlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          SettingsRow(icon: Icons.notifications_none, label: "Bildirimler", value: "Açık"),
                          const Divider(height: 1),
                          SettingsRow(icon: Icons.dark_mode_outlined, label: "Karanlık Mod", value: "Kapalı"),
                          const Divider(height: 1),
                          SettingsRow(icon: Icons.language, label: "Dil", value: "Türkçe"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Destek
                    const Text("Destek", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          SettingsRow(icon: Icons.help_outline, label: "Yardım & Destek"),
                          const Divider(height: 1),
                          SettingsRow(
                            icon: Icons.report_problem_outlined,
                            label: "Sorun Bildir",
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
                          ),
                          const Divider(height: 1),
                          SettingsRow(icon: Icons.privacy_tip_outlined, label: "Gizlilik Politikası"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.destructiveColor,
                          side: const BorderSide(color: AppTheme.destructiveColor),
                        ),
                        onPressed: () {
                          context.read<AuthProvider>().logout();
                          context.go('/login');
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text("Çıkış Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}