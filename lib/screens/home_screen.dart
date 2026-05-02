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
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final dividerColor = Theme.of(context).dividerColor;

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
                  childAspectRatio: 0.72,
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
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: DataService.todayDashboardMenuStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildTodayMenuCard(
                        context,
                        meal: "Menü yükleniyor...",
                        desc: "Firebase üzerinden güncel menü hazırlanıyor.",
                        time: "-",
                        price: "-",
                        note: "Bugünün menüsü merkezi veritabanından alınır.",
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildTodayMenuCard(
                        context,
                        meal: "Menü bilgisi alınamadı",
                        desc: "Lütfen daha sonra tekrar deneyin.",
                        time: "-",
                        price: "-",
                        note: "Firebase bağlantısı kontrol edilmeli.",
                      );
                    }

                    final menu = snapshot.data ?? {};
                    final items = menu['items'] as List<dynamic>? ?? [];
                    final mealName = menu['menuName']?.toString() ??
                        menu['mealType']?.toString() ??
                        "Bugünün Menüsü";
                    final desc = _menuDescription(items);
                    final price = menu['price']?.toString() ?? "-";
                    final time = menu['time']?.toString() ?? "-";
                    final note = menu['dashboardMessage']?.toString() ??
                        "Bugünün menüsü güncel güne göre gösteriliyor.";

                    return _buildTodayMenuCard(
                      context,
                      meal: mealName,
                      desc: desc,
                      time: time,
                      price: price,
                      note: note,
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              FutureBuilder<Map<String, dynamic>>(
                future: DataService.loadDatabase(),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? {};
                  final announcements = data['announcements'] as List<dynamic>? ?? [];
                  final events = data['events'] as List<dynamic>? ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const SectionHeader(title: "Son Duyurular"),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: announcements.take(2).map((announcement) {
                            final item = Map<dynamic, dynamic>.from(announcement as Map);
                            return InfoCard(
                              title: item['title']?.toString() ?? '',
                              subtitle: _announcementDateText(item),
                              metadata: item['content']?.toString() ?? '',
                              badge: item['isNew'] == true
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
                          children: events.take(2).map((event) {
                            final item = Map<dynamic, dynamic>.from(event as Map);
                            return InfoCard(
                              title: item['title']?.toString() ?? '',
                              subtitle: "${item['date'] ?? ''} • ${item['time'] ?? ''}",
                              metadata: item['location']?.toString() ?? '',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventDetailScreen(eventData: item),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
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
        children: const [
          Row(
            children: [
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
          SizedBox(height: 16),
          AppSearchBar(
            placeholder: "Kampüste ara...",
            readOnly: true,
          ),
        ],
      ),
    );
  }

  String _announcementDateText(Map<dynamic, dynamic> item) {
    final publishDate = item['publishDate']?.toString() ?? '';
    final publishTime = item['publishTime']?.toString() ?? '';
    final date = item['date']?.toString() ?? '';

    if (publishDate.isNotEmpty && publishTime.isNotEmpty) {
      return "$publishDate • $publishTime";
    }

    return date;
  }

  String _menuDescription(List<dynamic> items) {
    if (items.isEmpty) return "Menü bilgisi bulunamadı.";

    final names = items.take(4).map((item) {
      if (item is Map) {
        final name = item['name']?.toString() ?? "";
        final price = item['price']?.toString() ?? "";
        return price.isEmpty ? name : "$name $price";
      }
      return item.toString();
    }).where((text) => text.trim().isNotEmpty).toList();

    if (items.length > 4) names.add("...");

    return names.join(", ");
  }

  Widget _buildTodayMenuCard(
      BuildContext context, {
        required String meal,
        required String desc,
        required String time,
        required String price,
        required String note,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final dividerColor = Theme.of(context).dividerColor;
    final hasPrice = price.trim().isNotEmpty && price.trim() != "-";
    final badgeText = hasPrice ? price : "Kapalı";

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
                    note,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
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
                color: hasPrice ? AppTheme.successColor : AppTheme.textMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
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