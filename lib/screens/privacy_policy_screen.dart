import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import 'privacy_policy_screen.dart';


class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Privacy Policy",
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),

            _PolicySection(
              icon: Icons.info_outline,
              title: "1. General Information",
              content:
              "The My Culture application is developed to make campus life more organized and accessible. "
                  "This policy explains what information is displayed within the app, how it is processed, and how it is used to improve the user experience.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.person_outline,
              title: "2. Collected Information",
              content:
              "The application may display or temporarily store some basic data such as username, student number, favorites, joined events, and in-app preference information. "
                  "This information is used to personalize the user experience.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.settings_outlined,
              title: "3. Use of Information",
              content:
              "The collected or displayed information is used to provide suitable screens to the user, display favorite contents, list event participations, and manage the application flow. "
                  "The data is not used for any purpose other than improving the user experience.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.share_outlined,
              title: "4. Sharing with Third Parties",
              content:
              "User information is not shared with third parties unless there is a clear legal obligation or user consent. "
                  "The data shown within the application is only evaluated within the scope of the system's operation.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.lock_outline,
              title: "5. Data Security",
              content:
              "Reasonable technical and design measures are taken to protect user information. "
                  "However, no digital system is completely risk-free. Therefore, users are also expected to use their account information carefully.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.visibility_outlined,
              title: "6. User Rights",
              content:
              "Users can review the information displayed in the application; they can provide feedback via support channels for incorrect or outdated information. "
                  "Updating or correcting data can be requested when necessary.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.update_outlined,
              title: "7. Policy Updates",
              content:
              "This privacy policy may be updated according to needs. When significant changes occur, it is aimed to inform the user within the application.",
            ),
            const SizedBox(height: 16),

            _PolicySection(
              icon: Icons.mail_outline,
              title: "8. Contact",
              content:
              "For your questions or feedback regarding the privacy policy, you can contact us through the “Report Issue” section within the application.",
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryLight.withOpacity(0.20),
                ),
              ),
              child: const Text(
                "This screen is currently prepared for in-app informational purposes. "
                    "If a real release is to be made, the text should be reviewed again according to legal and corporate requirements.",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_outlined,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 12),
          const Text(
            "Protection of User Data",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Information text regarding the basic user data displayed and processed in the application.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              AppBadge(
                label: "Last Updated: 2026",
                backgroundColor: Colors.white24,
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _PolicySection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}