import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";

  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _filters = [
    "Tümü",
    "Akademik",
    "İdari",
    "Burs",
    "Genel",
  ];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  bool _isAnnouncementPublished(Map<dynamic, dynamic> announcement) {
    final publishAt = announcement['publishAt'];

    if (publishAt == null) {
      return true;
    }

    if (publishAt is Timestamp) {
      return !publishAt.toDate().isAfter(DateTime.now());
    }

    if (publishAt is DateTime) {
      return !publishAt.isAfter(DateTime.now());
    }

    return true;
  }

  DateTime? _getAnnouncementDateTime(Map<dynamic, dynamic> announcement) {
    final publishAt = announcement['publishAt'];
    final createdAt = announcement['createdAt'];
    final updatedAt = announcement['updatedAt'];

    if (publishAt is Timestamp) return publishAt.toDate();
    if (publishAt is DateTime) return publishAt;

    if (createdAt is Timestamp) return createdAt.toDate();
    if (createdAt is DateTime) return createdAt;

    if (updatedAt is Timestamp) return updatedAt.toDate();
    if (updatedAt is DateTime) return updatedAt;

    return null;
  }

  String _formatAnnouncementMetadata(Map<dynamic, dynamic> announcement) {
    final dateTime = _getAnnouncementDateTime(announcement);

    if (dateTime == null) {
      return announcement['date']?.toString() ?? "";
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return "Az önce";
    }

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} dk önce";
    }

    if (difference.inHours < 24) {
      return "${difference.inHours} saat önce";
    }

    if (difference.inDays == 1) {
      return "Dün";
    }

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return "$day/$month/$year • $hour:$minute";
  }

  String _mapSelectedFilterToCategory(String selectedFilter) {
    if (selectedFilter == "Akademik") return "academic";
    if (selectedFilter == "İdari") return "admin";
    if (selectedFilter == "Burs") return "scholarship";
    if (selectedFilter == "Genel") return "general";
    return "Tümü";
  }

  List<dynamic> _sortAnnouncements(List<dynamic> announcements) {
    final sorted = List<dynamic>.from(announcements);

    sorted.sort((a, b) {
      final aDate = _getAnnouncementDateTime(a as Map<dynamic, dynamic>);
      final bDate = _getAnnouncementDateTime(b as Map<dynamic, dynamic>);

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Duyurular"),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _databaseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Veri yüklenemedi: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Gösterilecek duyuru bulunamadı."),
            );
          }

          final allAnnouncements =
              snapshot.data!['announcements'] as List<dynamic>? ?? [];

          final mappedFilter = _mapSelectedFilterToCategory(_selectedFilter);
          final normalizedSearch = _searchQuery.toLowerCase().trim();

          final filteredAnnouncements = allAnnouncements.where((announcement) {
            final a = announcement as Map<dynamic, dynamic>;

            if (!_isAnnouncementPublished(a)) {
              return false;
            }

            final title = a['title']?.toString().toLowerCase() ?? "";
            final content = a['content']?.toString().toLowerCase() ?? "";
            final category = a['category']?.toString() ?? "general";

            final matchesSearch = normalizedSearch.isEmpty ||
                title.contains(normalizedSearch) ||
                content.contains(normalizedSearch);

            final matchesFilter =
                _selectedFilter == "Tümü" || category == mappedFilter;

            return matchesSearch && matchesFilter;
          }).toList();

          final sortedAnnouncements = _sortAnnouncements(filteredAnnouncements);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppSearchBar(
                  placeholder: "Duyuru ara...",
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];

                    return AppFilterChip(
                      label: filter,
                      active: _selectedFilter == filter,
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: sortedAnnouncements.isEmpty
                    ? const Center(
                  child: Text(
                    "Aramanıza uygun duyuru bulunamadı.",
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: sortedAnnouncements.length,
                  itemBuilder: (context, index) {
                    final announcement =
                    sortedAnnouncements[index] as Map<dynamic, dynamic>;

                    return InfoCard(
                      title: announcement['title']?.toString() ?? "",
                      subtitle: announcement['content']?.toString() ?? "",
                      metadata: _formatAnnouncementMetadata(announcement),
                      showChevron: false,
                      badge: announcement['isNew'] == true
                          ? const AppBadge(
                        label: "Yeni",
                        backgroundColor: AppTheme.primaryColor,
                        textColor: Colors.white,
                      )
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}