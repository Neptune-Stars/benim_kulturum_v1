import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Help & Support",
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dividerColor),
              ),
              child: Column(
                children: const [
                  _FaqTile(
                    question: "How do I find a classroom or campus location?",
                    answer:
                    "Open the classroom or campus section and search by classroom name, building, campus, or floor. The app shows the available location details so you can find where you need to go more easily.",
                  ),
                  Divider(height: 1),
                  _FaqTile(
                    question: "Where can I see the cafeteria menu?",
                    answer:
                    "You can check the cafeteria section to view the current daily or weekly menu. If a day is closed by the administration, it will be shown as unavailable in the app.",
                  ),
                  Divider(height: 1),
                  _FaqTile(
                    question: "How can I report a campus or technical issue?",
                    answer:
                    "Go to Help & Support and select Report an Issue. Choose the issue category, describe the problem clearly, and submit it. The administration can review the report from the admin panel.",
                  ),
                  Divider(height: 1),
                  _FaqTile(
                    question: "How do I change my profile avatar?",
                    answer:
                    "Open your profile page, tap the avatar area, and choose one of the available profile avatar options. Your selected avatar is saved to your student account and will appear again after login.",
                  ),
                  Divider(height: 1),
                  _FaqTile(
                    question: "Why can’t I upload my own profile photo?",
                    answer:
                    "The app currently uses predefined avatar options instead of gallery uploads so that the selected profile image can be saved safely with the student account and used across devices.",
                  ),
                  Divider(height: 1),
                  _FaqTile(
                    question: "Where can I see announcements and events?",
                    answer:
                    "Announcements and events are listed in their own sections. New updates added by the administration are shown in the app so students can follow campus news and activities.",
                  ),
                  Divider(height: 1),
                  _FaqTile(
                    question: "Can I see campus prices in the app?",
                    answer:
                    "Yes. The prices section shows available campus-related price information such as food, drinks, and other listed items. These records are managed by the admin panel.",
                  ),
                  Divider(height: 1),
                  _FaqTile(
                    question: "Who should I contact if the information looks wrong?",
                    answer:
                    "If you notice incorrect classroom, cafeteria, event, price, or announcement information, you can report it through the issue reporting screen or contact support during support hours.",
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final dividerColor = Theme.of(context).dividerColor;
    final cardColor = Theme.of(context).cardColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: mutedColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      iconColor: AppTheme.primaryColor,
      collapsedIconColor: AppTheme.primaryColor,
      title: Text(
        question,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: mutedColor,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}