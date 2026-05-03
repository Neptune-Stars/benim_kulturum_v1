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
  String _selectedFilter = "All";

  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _filters = [
    "All",
    "Academic",
    "Admin",
    "Scholarship",
    "General",
  ];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  bool _isAnnouncementPublished(Map<dynamic, dynamic> announcement) {
    final publishAt = announcement['publishAt'];
    if (publishAt == null) return true;
    if (publishAt is Timestamp) return !publishAt.toDate().isAfter(DateTime.now());
    if (publishAt is DateTime) return !publishAt.isAfter(DateTime.now());
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
    if (dateTime == null) return announcement['date']?.toString() ?? "";

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays == 1) return "Yesterday";

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return "$day/$month/$year";
  }

  String _mapSelectedFilterToCategory(String selectedFilter) {
    switch (selectedFilter) {
      case "Academic": return "academic";
      case "Admin": return "admin";
      case "Scholarship": return "scholarship";
      case "General": return "general";
      default: return "All";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Announcements"),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _databaseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: Text("No announcements found."));

          final allAnnouncements = snapshot.data!['announcements'] as List<dynamic>? ?? [];
          final mappedFilter = _mapSelectedFilterToCategory(_selectedFilter);
          final normalizedSearch = _searchQuery.toLowerCase().trim();

          final filtered = allAnnouncements.where((announcement) {
            final a = announcement as Map<dynamic, dynamic>;
            if (!_isAnnouncementPublished(a)) return false;

            final title = a['title']?.toString().toLowerCase() ?? "";
            final content = a['content']?.toString().toLowerCase() ?? "";
            final category = a['category']?.toString() ?? "general";

            final matchesSearch = normalizedSearch.isEmpty || title.contains(normalizedSearch) || content.contains(normalizedSearch);
            final matchesFilter = _selectedFilter == "All" || category == mappedFilter;

            return matchesSearch && matchesFilter;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppSearchBar(
                  placeholder: "Search announcements...",
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    return AppFilterChip(
                      label: _filters[index],
                      active: _selectedFilter == _filters[index],
                      onTap: () => setState(() => _selectedFilter = _filters[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text("No announcements matching your search.", style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final a = filtered[index] as Map<dynamic, dynamic>;
                    return InfoCard(
                      title: a['title']?.toString() ?? "",
                      subtitle: a['content']?.toString() ?? "",
                      metadata: _formatAnnouncementMetadata(a),
                      badge: a['isNew'] == true ? const AppBadge(label: "New", backgroundColor: AppTheme.primaryColor) : null,
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