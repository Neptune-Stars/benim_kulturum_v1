import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/settings_row.dart';
import '../widgets/badge_widget.dart';

import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/joined_events_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';

import 'report_issue_screen.dart';
import 'favorites_screen.dart';
import 'events_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_support_screen.dart';
import 'support_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _showProfilePhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
        final mutedColor = Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextMuted : AppTheme.textMuted;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Profil Fotoğrafı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
                  title: Text("Galeriden Seç", style: TextStyle(color: textColor)),
                  subtitle: Text("Profil fotoğrafı ekle", style: TextStyle(color: mutedColor)),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await context.read<ProfileProvider>().pickProfileImageFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppTheme.destructiveColor),
                  title: Text("Fotoğrafı Kaldır", style: TextStyle(color: textColor)),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await context.read<ProfileProvider>().removeProfileImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final imagePath = profileProvider.profileImagePath;

        return GestureDetector(
          onTap: () => _showProfilePhotoOptions(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).cardColor,
                backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
                child: imagePath == null ? const Icon(Icons.person, size: 48, color: AppTheme.primaryColor) : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final switchTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final switchMutedColor = Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: switchMutedColor),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: switchTextColor))),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favCount = context.watch<FavoritesProvider>().favorites.length;
    final joinedCount = context.watch<JoinedEventsProvider>().joinedCount;

    // YENİ: AuthProvider'dan giriş yapan kullanıcının verisini çekiyoruz
    final authProvider = context.watch<AuthProvider>();
    final userData = authProvider.userData ?? {};

    final String userName = userData['name'] ?? 'İsimsiz Kullanıcı';
    final String userNo = userData['no'] ?? 'Numara Yok';
    final String userGrade = userData['grade'] ?? 'Bilgi Yok';

    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    _buildProfileAvatar(context),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userNo,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppBadge(
                      label: userGrade,
                      backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                      textColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  children: [
                                    Text(favCount.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                    const SizedBox(height: 4),
                                    Text("Favori", style: TextStyle(color: mutedColor)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen(showOnlyJoined: true))),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  children: [
                                    Text(joinedCount.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                    const SizedBox(height: 4),
                                    Text("Etkinliklerim", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: mutedColor)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text("Ayarlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          Consumer<NotificationProvider>(
                            builder: (context, notificationProvider, _) {
                              return _buildSwitchRow(
                                context: context, icon: Icons.notifications_none, label: "Bildirimler",
                                value: notificationProvider.notificationsEnabled,
                                onChanged: (value) => context.read<NotificationProvider>().setNotifications(value),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return _buildSwitchRow(
                                context: context, icon: Icons.dark_mode_outlined, label: "Karanlık Mod",
                                value: themeProvider.isDarkMode,
                                onChanged: (value) => context.read<ThemeProvider>().setDarkMode(value),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          const SettingsRow(icon: Icons.language, label: "Dil", value: "Türkçe"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("Destek", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          //  Live Support eklendi
                          SettingsRow(
                            icon: Icons.chat_bubble_outline,
                            label: "Live Support",
                            onTap: () {
                              final String currentUserId = userData['id']?.toString() ?? "anon";
                              final String currentUserName = userData['name'] ?? "Student";

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => SupportChatScreen(
                                        userId: currentUserId,
                                        userName: currentUserName,
                                      )
                                  )
                              );
                            },
                          ),
                          const Divider(height: 1),
                          SettingsRow(icon: Icons.help_outline, label: "Yardım & Destek", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
                          const Divider(height: 1),
                          SettingsRow(icon: Icons.report_problem_outlined, label: "Sorun Bildir", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen()))),
                          const Divider(height: 1),
                          SettingsRow(icon: Icons.privacy_tip_outlined, label: "Gizlilik Politikası", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
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