import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../data/data_service.dart';

import '../widgets/search_bar_widget.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/info_card.dart';

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
import 'search_screen.dart';
import 'notifications_screen.dart';

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
                  "Quick Access",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.18,
                  children: [
                    QuickActionCard(
                      icon: Icons.meeting_room_outlined,
                      title: "Classrooms",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClassroomsScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.groups_outlined,
                      title: "Instructors",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InstructorsScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.access_time_outlined,
                      title: "Office Hours",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OfficeHoursScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.attach_money,
                      title: "Prices",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CampusPricesScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.event_note_outlined,
                      title: "Events",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EventsScreen(),
                        ),
                      ),
                    ),
                    QuickActionCard(
                      icon: Icons.report_problem_outlined,
                      title: "Report Issue",
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

              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionHeader(
                  title: "Today's Menu",
                  actionLabel: "See All",
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
                        meal: "Loading menu...",
                        desc: "Up-to-date menu is being prepared via Firebase.",
                        time: "-",
                        price: "-",
                        note: "Today's menu is retrieved from the central database.",
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildTodayMenuCard(
                        context,
                        meal: "Could not retrieve menu",
                        desc: "Please try again later.",
                        time: "-",
                        price: "-",
                        note: "Check Firebase connection.",
                      );
                    }

                    final menu = snapshot.data ?? {};
                    final items = menu['items'] as List<dynamic>? ?? [];
                    final mealName = menu['menuName']?.toString() ??
                        menu['mealType']?.toString() ??
                        "Today's Menu";
                    final desc = _menuDescription(items);
                    final price = menu['price']?.toString() ?? "-";
                    final time = menu['time']?.toString() ?? "-";
                    final note = menu['dashboardMessage']?.toString() ??
                        "Today's menu is shown based on the current day.";

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

                  final announcements = _sortAnnouncements(
                    _filterUpcoming(
                      data['announcements'] as List<dynamic>? ?? [],
                      _announcementDateTime,
                    ),
                  );

                  final events = _sortEventsAscending(
                    _filterUpcoming(
                      data['events'] as List<dynamic>? ?? [],
                      _eventDateTime,
                    ),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Recent Announcements ──────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SectionHeader(
                          title: "Recent Announcements",
                          actionLabel: announcements.isEmpty ? null : "See All",
                          onAction: announcements.isEmpty
                              ? null
                              : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AnnouncementsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: announcements.take(2).map((announcement) {
                            final item = Map<dynamic, dynamic>.from(
                                announcement as Map);
                            return InfoCard(
                              title: item['title']?.toString() ?? '',
                              subtitle: _announcementDateText(item),
                              metadata: item['content']?.toString() ?? '',
                              badge: null,
                              showChevron: false,
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Upcoming Events ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SectionHeader(
                          title: "Upcoming Events",
                          actionLabel: events.isEmpty ? null : "See All",
                          onAction: events.isEmpty
                              ? null
                              : () => Navigator.push(
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
                            final item =
                            Map<dynamic, dynamic>.from(event as Map);
                            return InfoCard(
                              title: item['title']?.toString() ?? '',
                              subtitle:
                              "${item['date'] ?? ''} • ${item['time'] ?? ''}",
                              metadata: item['location']?.toString() ?? '',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EventDetailScreen(eventData: item),
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

  // ─────────────────────────────────────────────────────────────────────────
  // Header & Notification button
  // ─────────────────────────────────────────────────────────────────────────

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
            children: [
              const Expanded(
                child: Text(
                  "Hello, Student 👋",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildNotificationButton(context),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            child: const AbsorbPointer(
              child: AppSearchBar(
                placeholder: "Search on campus...",
                readOnly: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 28,
              ),
              tooltip: "Notifications",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.destructiveColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 9 ? "9+" : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Date parsing — handles every format seen in Firestore
  // ─────────────────────────────────────────────────────────────────────────

  static const Map<String, int> _monthMap = {
    'january': 1,   'february': 2,  'march': 3,     'april': 4,
    'may': 5,       'june': 6,      'july': 7,       'august': 8,
    'september': 9, 'october': 10,  'november': 11,  'december': 12,
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
    'jun': 6, 'jul': 7, 'aug': 8,
    'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// Parses any of the following into a [DateTime]:
  ///   • Firestore [Timestamp]          → .toDate()
  ///   • Dart [DateTime]                → as-is
  ///   • ISO-8601 string                → "2026-05-10" / "2026-05-10T13:00:00Z"
  ///   • DD/MM/YYYY string              → "28/05/2026"
  ///   • "Month D, YYYY" string         → "May 10, 2026"
  ///   • "D Month YYYY" string          → "10 May 2026"
  ///
  /// Returns `null` when the value cannot be interpreted as a date.
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    // Firestore Timestamp
    if (value is Timestamp) return value.toDate();

    // Already a DateTime
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    // ISO 8601 — covers "2026-05-10" and "2026-05-10T13:00:00..."
    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    // DD/MM/YYYY  e.g. "28/05/2026"
    final ddmmyyyy =
    RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
    if (ddmmyyyy != null) {
      final d = int.tryParse(ddmmyyyy.group(1)!);
      final m = int.tryParse(ddmmyyyy.group(2)!);
      final y = int.tryParse(ddmmyyyy.group(3)!);
      if (d != null && m != null && y != null) return DateTime(y, m, d);
    }

    // "Month D, YYYY"  e.g. "May 10, 2026"
    final mdy =
    RegExp(r'^([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})$').firstMatch(text);
    if (mdy != null) {
      final m = _monthMap[mdy.group(1)!.toLowerCase()];
      final d = int.tryParse(mdy.group(2)!);
      final y = int.tryParse(mdy.group(3)!);
      if (m != null && d != null && y != null) return DateTime(y, m, d);
    }

    // "D Month YYYY"  e.g. "10 May 2026"
    final dmy =
    RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$').firstMatch(text);
    if (dmy != null) {
      final d = int.tryParse(dmy.group(1)!);
      final m = _monthMap[dmy.group(2)!.toLowerCase()];
      final y = int.tryParse(dmy.group(3)!);
      if (d != null && m != null && y != null) return DateTime(y, m, d);
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Per-collection date extractors
  // ─────────────────────────────────────────────────────────────────────────

  /// Priority: publishAt → publishDate → date → createdAt → updatedAt
  DateTime? _announcementDateTime(Map<dynamic, dynamic> item) {
    for (final field in ['publishAt', 'publishDate', 'date', 'createdAt', 'updatedAt']) {
      final parsed = _parseDate(item[field]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Priority: startAt → date → eventDate → startDate → datetime
  DateTime? _eventDateTime(Map<dynamic, dynamic> item) {
    for (final field in ['startAt', 'date', 'eventDate', 'startDate', 'datetime']) {
      final parsed = _parseDate(item[field]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filter & sort helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Today at midnight — items whose date equals today are kept.
  DateTime _todayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Generic filter: keeps items whose date (via [dateExtractor]) is ≥ today.
  /// Items with no parsable date are excluded.
  List<dynamic> _filterUpcoming(
      List<dynamic> items,
      DateTime? Function(Map<dynamic, dynamic>) dateExtractor,
      ) {
    final todayStart = _todayStart();
    return items.where((raw) {
      final item = Map<dynamic, dynamic>.from(raw as Map);
      final date = dateExtractor(item);
      if (date == null) return false;
      final dateOnly = DateTime(date.year, date.month, date.day);
      return !dateOnly.isBefore(todayStart);
    }).toList();
  }

  /// Announcements: newest publish date first (descending).
  List<dynamic> _sortAnnouncements(List<dynamic> items) {
    final sorted = List<dynamic>.from(items);
    sorted.sort((a, b) {
      final aDate = _announcementDateTime(Map<dynamic, dynamic>.from(a as Map));
      final bDate = _announcementDateTime(Map<dynamic, dynamic>.from(b as Map));
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate); // descending
    });
    return sorted;
  }

  /// Events: soonest event first (ascending).
  List<dynamic> _sortEventsAscending(List<dynamic> items) {
    final sorted = List<dynamic>.from(items);
    sorted.sort((a, b) {
      final aDate = _eventDateTime(Map<dynamic, dynamic>.from(a as Map));
      final bDate = _eventDateTime(Map<dynamic, dynamic>.from(b as Map));
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate); // ascending
    });
    return sorted;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Small UI helpers
  // ─────────────────────────────────────────────────────────────────────────

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
    if (items.isEmpty) return "Menu information not found.";

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

  // ─────────────────────────────────────────────────────────────────────────
  // Today's menu card
  // ─────────────────────────────────────────────────────────────────────────

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
    final badgeText = hasPrice ? price : "Closed";

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen()),
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