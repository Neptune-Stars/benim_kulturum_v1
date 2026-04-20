import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../data/mock_data.dart';

import '../widgets/search_bar_widget.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';

import 'classrooms_screen.dart';
import 'buildings_screen.dart';
import 'instructors_screen.dart';
import 'office_hours_screen.dart';
import 'cafeteria_menu_screen.dart';
import 'campus_prices_screen.dart';
import 'events_screen.dart';
import 'report_issue_screen.dart';
import 'announcements_screen.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final dividerColor = Theme.of(context).dividerColor;

    final todayMenu = MockData.events.isNotEmpty
        ? {
      "title": "Günün Menüsü",
      "meal": "Günün Menüsü",
      "desc": "Mercimek çorbası, tavuk şinitzel, pilav, salata",
      "time": "12:00 - 17:00",
      "price": "₺35",
    }
        : {
      "title": "Günün Menüsü",
      "meal": "Günün Menüsü",
      "desc": "Menü bilgisi bulunamadı",
      "time": "-",
      "price": "-",
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Hızlı Erişim",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.88,
                  children: [
                    QuickActionCard(
                      icon: Icons.meeting_room_outlined,
                      title: "Derslikler",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClassroomsScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.business,
                      title: "Kampüs\nRehberi",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BuildingsScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.groups_outlined,
                      title: "Hocalar",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InstructorsScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.access_time_outlined,
                      title: "Ofis Saatleri",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OfficeHoursScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.restaurant_menu,
                      title: "Menü",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CafeteriaMenuScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.attach_money,
                      title: "Fiyatlar",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CampusPricesScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.event_note_outlined,
                      title: "Etkinlikler",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EventsScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.report_problem_outlined,
                      title: "Sorun Bildir",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportIssueScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionHeader(
                  title: "Bugünün Menüsü",
                  actionLabel: "Tümünü Gör",
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CafeteriaMenuScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTodayMenuCard(
                  context,
                  meal: todayMenu["meal"]!,
                  desc: todayMenu["desc"]!,
                  time: todayMenu["time"]!,
                  price: todayMenu["price"]!,
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const SectionHeader(title: "Son Duyurular"),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: MockData.announcements.take(2).map((announcement) {
                    return InfoCard(
                      title: announcement.title,
                      subtitle: announcement.date,
                      metadata: announcement.content,
                      badge: announcement.isNew
                          ? const AppBadge(label: "Yeni")
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnnouncementsScreen(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionHeader(
                  title: "Yaklaşan Etkinlikler",
                  actionLabel: "Tümünü Gör",
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EventsScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: MockData.events.take(2).map((event) {
                    return InfoCard(
                      title: event.title,
                      subtitle: "${event.date} • ${event.time}",
                      metadata: event.location,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailScreen(event: event),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: dividerColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
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
            children: const [
              Expanded(
                child: Text(
                  "Merhaba, Öğrenci 👋",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.notifications_none,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AppSearchBar(
            placeholder: "Kampüste ara...",
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMenuCard(
      BuildContext context, {
        required String meal,
        required String desc,
        required String time,
        required String price,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final dividerColor = Theme.of(context).dividerColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CafeteriaMenuScreen(),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 14,
                      color: mutedColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}