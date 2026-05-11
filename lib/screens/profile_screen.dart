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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _showProfilePhotoOptions(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final studentDocId = authProvider.currentUserDocId;

    if (studentDocId == null || studentDocId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Student information could not be found."),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        final textColor =
            Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;

        final mutedColor = Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkTextMuted
            : AppTheme.textMuted;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Consumer<ProfileProvider>(
              builder: (context, profileProvider, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Choose Profile Avatar",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Select one of the available profile options.",
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),

                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: ProfileProvider.avatarOptions.map((avatar) {
                        final isSelected =
                            profileProvider.selectedAvatarId == avatar.id;

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            Navigator.pop(bottomSheetContext);

                            try {
                              await context.read<ProfileProvider>().selectAvatar(
                                studentDocId: studentDocId,
                                avatarId: avatar.id,
                              );

                              context.read<AuthProvider>().updateUserData({
                                'profileAvatarId': avatar.id,
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Profile avatar updated."),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Avatar could not be saved."),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: avatar.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? avatar.color
                                    : Theme.of(context).dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              avatar.icon,
                              color: avatar.color,
                              size: 30,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.destructiveColor,
                      ),
                      title: Text(
                        "Remove Avatar",
                        style: TextStyle(color: textColor),
                      ),
                      onTap: () async {
                        Navigator.pop(bottomSheetContext);

                        try {
                          await context.read<ProfileProvider>().removeAvatar(
                            studentDocId: studentDocId,
                          );

                          context.read<AuthProvider>().updateUserData({
                            'profileAvatarId': '',
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Profile avatar removed."),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Avatar could not be removed."),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final authAvatarId =
        context.watch<AuthProvider>().userData?['profileAvatarId']?.toString();

        if ((profileProvider.selectedAvatarId == null ||
            profileProvider.selectedAvatarId!.isEmpty) &&
            authAvatarId != null &&
            authAvatarId.isNotEmpty) {
          profileProvider.initializeFromUserData({
            'profileAvatarId': authAvatarId,
          });
        }

        final avatar = profileProvider.selectedAvatar;

        return GestureDetector(
          onTap: () => _showProfilePhotoOptions(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: avatar.color.withOpacity(0.14),
                child: Icon(
                  avatar.icon,
                  size: 46,
                  color: avatar.color,
                ),
              ),
              if (profileProvider.isSaving)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
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
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
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

    final authProvider = context.watch<AuthProvider>();
    final userData = authProvider.userData ?? {};

    final String userName = userData['name'] ?? 'Unknown User';
    final String userNo = userData['no'] ?? 'No Number';
    final String userGrade = userData['grade'] ?? 'No Info';

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
                                    Text("Favorites", style: TextStyle(color: mutedColor)),
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
                                    Text("My Events", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: mutedColor)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          Consumer<NotificationProvider>(
                            builder: (context, notificationProvider, _) {
                              return _buildSwitchRow(
                                context: context, icon: Icons.notifications_none, label: "Notifications",
                                value: notificationProvider.notificationsEnabled,
                                onChanged: (value) => context.read<NotificationProvider>().setNotifications(value),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return _buildSwitchRow(
                                context: context, icon: Icons.dark_mode_outlined, label: "Dark Mode",
                                value: themeProvider.isDarkMode,
                                onChanged: (value) => context.read<ThemeProvider>().setDarkMode(value),
                              );
                            },
                          ),

                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("Support", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
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
                          SettingsRow(icon: Icons.help_outline, label: "Help & Support", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
                          const Divider(height: 1),
                          SettingsRow(icon: Icons.report_problem_outlined, label: "Report Issue", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen()))),
                          const Divider(height: 1),
                          SettingsRow(icon: Icons.privacy_tip_outlined, label: "Privacy Policy", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
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
                          context.read<ProfileProvider>().reset();
                          context.read<FavoritesProvider>().reset();
                          context.read<JoinedEventsProvider>().reset();
                          context.read<AuthProvider>().logout();
                          context.go('/login');
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text("Log Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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