import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart';

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
import 'building_detail_screen.dart';
import 'instructor_detail_screen.dart';
import 'classroom_detail_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _databaseFuture;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  String _normalizeForSearch(String text) {
    return text.toLowerCase()
        .replaceAll('i̇', 'i').replaceAll('ı', 'i').replaceAll('ğ', 'g')
        .replaceAll('ü', 'u').replaceAll('ş', 's').replaceAll('ö', 'o').replaceAll('ç', 'c');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
            future: _databaseFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data ?? {};

              final events = data['events'] as List<dynamic>? ?? [];
              final announcements = data['announcements'] as List<dynamic>? ?? [];
              final cafeteriaData = data['cafeteria'] as Map<dynamic, dynamic>? ?? {};
              final menus = cafeteriaData['menus'] as Map<dynamic, dynamic>? ?? {};
              final lunchMenu = menus['Öğle'] ?? {};
              final lunchItems = (lunchMenu['items'] as List<dynamic>? ?? []).join(", ");

              final Map<String, String> todayMenu = {
                "title": "Günün Menüsü",
                "meal": "Öğle Menüsü",
                "desc": lunchItems.isNotEmpty ? lunchItems : "Menü bilgisi bulunamadı",
                "time": lunchMenu['time']?.toString() ?? "-",
                "price": lunchMenu['price']?.toString() ?? "-",
              };

              // YENİ: Firebase'deki yeni duyuruları ve bu telefonda okunanları karşılaştır
              var userBox = Hive.box('userBox');
              List readIds = List.from(userBox.get('readAnnouncements', defaultValue: []));

              final int unreadCount = announcements.where(
                      (a) => a['isNew'] == true && !readIds.contains(a['id'])
              ).length;

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, unreadCount, announcements, readIds),
                    const SizedBox(height: 18),

                    if (_searchQuery.isEmpty) ...[
                      _buildDefaultHomeContent(context, todayMenu, announcements, events),
                    ]
                    else ...[
                      _buildSearchResults(context, data),
                    ]
                  ],
                ),
              );
            }
        ),
      ),
    );
  }

  // YENİ: Header artık announcements ve readIds verilerini de alıyor
  Widget _buildHeader(BuildContext context, int unreadCount, List<dynamic> announcements, List readIds) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(
                      "Merhaba, Öğrenci 👋",
                      style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)
                  )
              ),
              IconButton(
                onPressed: () async {
                  // YENİ: Zile tıklandığında, Firebase'i değiştirmek yerine
                  // bu kullanıcının "okudu" listesini Hive'a kaydediyoruz.
                  if (unreadCount > 0) {
                    var userBox = Hive.box('userBox');
                    for (var a in announcements) {
                      if (a['isNew'] == true && !readIds.contains(a['id'])) {
                        readIds.add(a['id']);
                      }
                    }
                    await userBox.put('readAnnouncements', readIds);

                    setState(() {}); // Kırmızı noktayı hemen kaldırmak için ekranı yenile
                  }

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  }
                },
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount.toString()),
                  backgroundColor: AppTheme.destructiveColor,
                  child: Icon(Icons.notifications_none, color: textColor, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSearchBar(
            placeholder: "Birim, hoca, derslik ara...",
            readOnly: false,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, Map<String, dynamic> data) {
    final sq = _normalizeForSearch(_searchQuery);

    final allUnits = data['buildings'] as List<dynamic>? ?? [];
    final allClassrooms = data['classrooms'] as List<dynamic>? ?? [];
    final allInstructors = data['instructors'] as List<dynamic>? ?? [];
    final allEvents = data['events'] as List<dynamic>? ?? [];

    List<Map<String, dynamic>> results = [];

    for (var u in allUnits) {
      if (_normalizeForSearch(u['name']?.toString() ?? '').contains(sq) || _normalizeForSearch(u['location']?.toString() ?? '').contains(sq)) {
        results.add({...u as Map, 'searchType': 'Kampüs Alanı'});
      }
    }
    for (var i in allInstructors) {
      if (_normalizeForSearch(i['name']?.toString() ?? '').contains(sq) || _normalizeForSearch(i['department']?.toString() ?? '').contains(sq)) {
        results.add({...i as Map, 'searchType': 'Hoca'});
      }
    }
    for (var c in allClassrooms) {
      if (_normalizeForSearch(c['name']?.toString() ?? '').contains(sq)) {
        results.add({...c as Map, 'searchType': 'Derslik'});
      }
    }
    for (var e in allEvents) {
      if (_normalizeForSearch(e['title']?.toString() ?? '').contains(sq)) {
        results.add({...e as Map, 'searchType': 'Etkinlik'});
      }
    }

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text("Sonuç bulunamadı.", style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
            child: Text("${results.length} sonuç bulundu", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          ),
          ...results.map((item) {
            String title = item['name'] ?? item['title'] ?? 'İsimsiz';
            String subtitle = item['department'] ?? item['location'] ?? item['building'] ?? '';
            String type = item['searchType'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: InfoCard(
                title: title,
                subtitle: subtitle,
                badge: AppBadge(label: type, backgroundColor: AppTheme.primaryLight.withOpacity(0.1), textColor: AppTheme.primaryColor),
                onTap: () {
                  if (type == 'Kampüs Alanı') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BuildingDetailScreen(buildingData: item)));
                  } else if (type == 'Hoca') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InstructorDetailScreen(instructorData: item)));
                  } else if (type == 'Derslik') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroomData: item)));
                  } else if (type == 'Etkinlik') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventData: item)));
                  }
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDefaultHomeContent(BuildContext context, Map<String, String> todayMenu, List<dynamic> announcements, List<dynamic> events) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final dividerColor = Theme.of(context).dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("Hızlı Erişim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 8, childAspectRatio: 0.72,
            children: [
              QuickActionCard(icon: Icons.meeting_room_outlined, title: "Derslikler", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassroomsScreen()))),
              QuickActionCard(icon: Icons.business, title: "Kampüs\nRehberi", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuildingsScreen()))),
              QuickActionCard(icon: Icons.groups_outlined, title: "Hocalar", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructorsScreen()))),
              QuickActionCard(icon: Icons.access_time_outlined, title: "Ofis Saatleri", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficeHoursScreen()))),
              QuickActionCard(icon: Icons.restaurant_menu, title: "Menü", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen()))),
              QuickActionCard(icon: Icons.attach_money, title: "Fiyatlar", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CampusPricesScreen()))),
              QuickActionCard(icon: Icons.event_note_outlined, title: "Etkinlikler", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()))),
              QuickActionCard(icon: Icons.report_problem_outlined, title: "Sorun Bildir", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen()))),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SectionHeader(title: "Bugünün Menüsü", actionLabel: "Tümünü Gör", onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen()))),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildTodayMenuCard(context, meal: todayMenu["meal"]!, desc: todayMenu["desc"]!, time: todayMenu["time"]!, price: todayMenu["price"]!),
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
            children: announcements.take(2).map((announcement) {
              final isNew = announcement['isNew'] == true;
              return InfoCard(
                title: announcement['title']?.toString() ?? '',
                subtitle: announcement['date']?.toString() ?? '',
                metadata: announcement['content']?.toString() ?? '',
                badge: isNew ? const AppBadge(label: "Yeni") : null,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SectionHeader(title: "Yaklaşan Etkinlikler", actionLabel: "Tümünü Gör", onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()))),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: events.take(2).map((event) {
              return InfoCard(
                title: event['title']?.toString() ?? '',
                subtitle: "${event['date']} • ${event['time']}",
                metadata: event['location']?.toString() ?? '',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventData: event))),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Divider(color: dividerColor)),
      ],
    );
  }

  Widget _buildTodayMenuCard(BuildContext context, {required String meal, required String desc, required String time, required String price}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final dividerColor = Theme.of(context).dividerColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: dividerColor)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 6),
                  Text(desc, style: TextStyle(fontSize: 14, color: mutedColor, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.successColor, borderRadius: BorderRadius.circular(12)),
              child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}