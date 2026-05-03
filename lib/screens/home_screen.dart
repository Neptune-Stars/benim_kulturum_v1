import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../data/data_service.dart';

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
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;

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
                child: Text("Quick Access", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
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
                  childAspectRatio: 0.72,
                  children: [
                    _QuickActionCard(
                        icon: Icons.meeting_room_outlined,
                        title: "Classrooms",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassroomsScreen()))
                    ),
                    _QuickActionCard(
                        icon: Icons.groups_outlined,
                        title: "Instructors",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructorsScreen()))
                    ),
                    _QuickActionCard(
                        icon: Icons.access_time_outlined,
                        title: "Hours",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficeHoursScreen()))
                    ),
                    _QuickActionCard(
                        icon: Icons.attach_money,
                        title: "Prices",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CampusPricesScreen()))
                    ),
                    _QuickActionCard(
                        icon: Icons.event_note_outlined,
                        title: "Events",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()))
                    ),
                    _QuickActionCard(
                        icon: Icons.report_problem_outlined,
                        title: "Report",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen()))
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionHeader(
                    title: "Today's Menu",
                    actionLabel: "See All",
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen()))
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: DataService.todayDashboardMenuStream(),
                  builder: (context, snapshot) {
                    final menu = snapshot.data ?? {};
                    return _buildTodayMenuCard(context,
                        meal: menu['menuName']?.toString() ?? "Loading Menu...",
                        desc: _menuDescription(menu['items'] as List? ?? []),
                        time: menu['time']?.toString() ?? "-",
                        price: menu['price']?.toString() ?? "-",
                        note: menu['dashboardMessage']?.toString() ?? "Updated daily.");
                  },
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<Map<String, dynamic>>(
                future: DataService.loadDatabase(),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? {};
                  final announcements = data['announcements'] as List? ?? [];
                  final events = data['events'] as List? ?? [];
                  return Column(
                    children: [
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SectionHeader(title: "Recent Announcements")),
                      ...announcements.take(2).map((a) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: InfoCard(
                            title: a['title'] ?? '',
                            subtitle: _announcementDateText(a),
                            metadata: a['content'] ?? '',
                            badge: a['isNew'] == true ? const AppBadge(label: "New") : null,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen()))
                        ),
                      )),
                      const SizedBox(height: 24),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SectionHeader(title: "Upcoming Events")),
                      ...events.take(2).map((e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: InfoCard(
                            title: e['title'] ?? '',
                            subtitle: "${e['date']} • ${e['time']}",
                            metadata: e['location'] ?? '',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventData: e)))
                        ),
                      )),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // BURASI DÜZELTİLDİ: primaryGradient yerine doğrudan renkler kullanıldı.
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
      child: Column(children: [
        Row(children: const [
          Expanded(child: Text("Hello, Student 👋", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
          Icon(Icons.notifications_none, color: Colors.white),
        ]),
        const SizedBox(height: 16),
        const AppSearchBar(placeholder: "Search on campus...", readOnly: true),
      ]),
    );
  }

  String _announcementDateText(Map<dynamic, dynamic> item) {
    final publishDate = item['publishDate']?.toString() ?? '';
    final publishTime = item['publishTime']?.toString() ?? '';
    return (publishDate.isNotEmpty && publishTime.isNotEmpty) ? "$publishDate • $publishTime" : (item['date']?.toString() ?? '');
  }

  String _menuDescription(List<dynamic> items) {
    if (items.isEmpty) return "Menu info not found.";
    final names = items.take(4).map((e) => e is Map ? e['name'] : e.toString()).toList();
    return names.join(", ") + (items.length > 4 ? "..." : "");
  }

  Widget _buildTodayMenuCard(BuildContext context, {required String meal, required String desc, required String time, required String price, required String note}) {
    final hasPrice = price.trim() != "-" && price.isNotEmpty;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor)
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(meal, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.3)),
            const SizedBox(height: 10),
            Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ])),
          const SizedBox(width: 12),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: hasPrice ? AppTheme.successColor : AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(12)
              ),
              child: Text(hasPrice ? price : "Closed", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
          ),
        ]),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(children: [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryLight.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primaryColor)
        ),
        const SizedBox(height: 8),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}