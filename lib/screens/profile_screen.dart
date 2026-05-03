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


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _showProfilePhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text("Select from Gallery"), onTap: () { Navigator.pop(context); context.read<ProfileProvider>().pickProfileImageFromGallery(); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text("Remove Photo"), onTap: () { Navigator.pop(context); context.read<ProfileProvider>().removeProfileImage(); }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userData = auth.userData ?? {};

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 60),
          _buildAvatar(context),
          const SizedBox(height: 16),
          Text(userData['name'] ?? 'Guest', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(userData['no'] ?? 'No ID', style: const TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          _buildStats(context),
          const SizedBox(height: 24),
          _buildSettings(context),
        ]),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final imagePath = context.watch<ProfileProvider>().profileImagePath;
    return GestureDetector(
      onTap: () => _showProfilePhotoOptions(context),
      child: CircleAvatar(radius: 50, backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null, child: imagePath == null ? const Icon(Icons.person, size: 50) : null),
    );
  }

  Widget _buildStats(BuildContext context) {
    final favCount = context.watch<FavoritesProvider>().favorites.length;
    final joinedCount = context.watch<JoinedEventsProvider>().joinedCount;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _statItem("Favorites", favCount.toString(), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
      _statItem("My Events", joinedCount.toString(), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen(showOnlyJoined: true)))),
    ]);
  }

  Widget _statItem(String label, String value, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)), Text(label, style: const TextStyle(fontSize: 12))]));
  }

  Widget _buildSettings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Card(child: Column(children: [
          _SwitchRow(label: "Notifications", icon: Icons.notifications, value: context.watch<NotificationProvider>().notificationsEnabled, onChanged: (v) => context.read<NotificationProvider>().setNotifications(v)),
          _SwitchRow(label: "Dark Mode", icon: Icons.dark_mode, value: context.watch<ThemeProvider>().isDarkMode, onChanged: (v) => context.read<ThemeProvider>().setDarkMode(v)),
        ])),
        const SizedBox(height: 16),
        Card(child: Column(children: [
          SettingsRow(label: "Help & Support", icon: Icons.help, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
          SettingsRow(label: "Report Issue", icon: Icons.report, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen()))),
          SettingsRow(label: "Privacy Policy", icon: Icons.lock, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
        ])),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () { context.read<AuthProvider>().logout(); context.go('/login'); }, child: const Text("Logout")),
      ]),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.label, required this.icon, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListTile(leading: Icon(icon), title: Text(label), trailing: Switch.adaptive(value: value, onChanged: onChanged));
}