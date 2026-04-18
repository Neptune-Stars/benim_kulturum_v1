import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/mock_data.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";

  final List<String> _filters = ["Tümü", "Akademik", "İdari", "Burs", "Genel"];

  @override
  Widget build(BuildContext context) {
    final filteredAnnouncements = MockData.announcements.where((a) {
      final matchesSearch = a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.content.toLowerCase().contains(_searchQuery.toLowerCase());

      final mappedFilter = _selectedFilter == "Akademik" ? "academic" :
      _selectedFilter == "İdari" ? "admin" :
      _selectedFilter == "Burs" ? "scholarship" :
      _selectedFilter == "Genel" ? "general" : "Tümü";

      final matchesFilter = _selectedFilter == "Tümü" || a.category == mappedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: "Duyurular"), // No back button since it's a bottom nav tab
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppSearchBar(
              placeholder: "Duyuru ara...",
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
                final filter = _filters[index];
                return AppFilterChip(
                  label: filter,
                  active: _selectedFilter == filter,
                  onTap: () => setState(() => _selectedFilter = filter),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredAnnouncements.length,
              itemBuilder: (context, index) {
                final a = filteredAnnouncements[index];
                return InfoCard(
                  title: a.title,
                  subtitle: a.content,
                  metadata: a.date,
                  showChevron: false,
                  badge: a.isNew
                      ? const AppBadge(label: "Yeni", backgroundColor: AppTheme.primaryColor, textColor: Colors.white)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}