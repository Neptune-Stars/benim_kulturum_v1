import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/mock_data.dart';

// Import screens for navigation
import 'buildings_screen.dart';
import 'classrooms_screen.dart';
import 'instructors_screen.dart';
import 'office_hours_screen.dart';
import 'cafeteria_menu_screen.dart';
import 'campus_prices_screen.dart';
import 'events_screen.dart';
import 'report_issue_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Merhaba, Öğrenci 👋",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppSearchBar(
                    placeholder: "Kampüste ara...",
                    readOnly: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  SectionHeader(title: "Hızlı Erişim"),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.8,
                    children: [
                      QuickActionCard(icon: Icons.meeting_room, title: "Derslikler", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassroomsScreen()))),
                      QuickActionCard(icon: Icons.business, title: "Binalar", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuildingsScreen()))),
                      QuickActionCard(icon: Icons.people, title: "Hocalar", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructorsScreen()))),
                      QuickActionCard(icon: Icons.access_time, title: "Ofis Saatleri", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficeHoursScreen()))),
                      QuickActionCard(icon: Icons.restaurant, title: "Menü", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen()))),
                      QuickActionCard(icon: Icons.attach_money, title: "Fiyatlar", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CampusPricesScreen()))),
                      QuickActionCard(icon: Icons.event, title: "Etkinlikler", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()))),
                      QuickActionCard(icon: Icons.report_problem, title: "Sorun Bildir", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen()))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Today's Menu
                  SectionHeader(
                    title: "Bugünün Menüsü",
                    actionLabel: "Tümünü Gör",
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen())),
                  ),
                  InfoCard(
                    title: "Öğle Yemeği",
                    subtitle: "Mercimek çorbası, tavuk şinitzel, pilav, salata",
                    metadata: "12:00 - 14:00",
                    badge: const AppBadge(label: "₺35", backgroundColor: AppTheme.successColor, textColor: Colors.white),
                    showChevron: false,
                  ),
                  const SizedBox(height: 16),

                  // Announcements
                  SectionHeader(title: "Son Duyurular"),
                  ...MockData.announcements.take(2).map((a) => InfoCard(
                    title: a.title,
                    subtitle: a.date,
                    badge: a.isNew ? const AppBadge(label: "Yeni", backgroundColor: AppTheme.primaryColor, textColor: Colors.white) : null,
                    showChevron: false,
                  )),

                  // Upcoming Events
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: "Yaklaşan Etkinlikler",
                    actionLabel: "Tümünü Gör",
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
                  ),
                  ...MockData.events.take(2).map((e) => InfoCard(
                    title: e.title,
                    subtitle: "${e.date} • ${e.time}",
                    metadata: e.location,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}