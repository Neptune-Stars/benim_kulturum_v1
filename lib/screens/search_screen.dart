import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart'; // JSON Servisi

// Import detail screens for navigation
import 'building_detail_screen.dart';
import 'classroom_detail_screen.dart';
import 'instructor_detail_screen.dart';
import 'event_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "Tümü";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _filters = ["Tümü", "Binalar", "Derslikler", "Hocalar", "Etkinlikler"];
  final List<String> _recentSearches = ["MF-101", "Kütüphane", "Ahmet Yılmaz", "Bahar Şenliği"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchController,
                      placeholder: "Kampüste ara...",
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ],
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
              child: _searchQuery.isEmpty
                  ? _buildRecentSearches()
                  : FutureBuilder<Map<String, dynamic>>(
                future: _databaseFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) return _buildEmptyState();

                  List<Widget> searchResults = _buildSearchResults(snapshot.data!);

                  return searchResults.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: searchResults,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Son Aramalar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) => ActionChip(
              label: Text(search),
              backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
              side: BorderSide.none,
              onPressed: () {
                _searchController.text = search;
                setState(() => _searchQuery = search);
              },
            )).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("Sonuç bulunamadı", style: TextStyle(fontSize: 18, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  List<Widget> _buildSearchResults(Map<String, dynamic> data) {
    List<Widget> results = [];
    final query = _searchQuery.toLowerCase();

    if (_selectedFilter == "Tümü" || _selectedFilter == "Binalar") {
      final buildings = data['buildings'] as List? ?? [];
      for (var b in buildings) {
        if (b['name'].toLowerCase().contains(query) || b['abbr'].toLowerCase().contains(query)) {
          results.add(InfoCard(
            title: b['name'], subtitle: b['location'], badge: const AppBadge(label: "Bina"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BuildingDetailScreen(buildingData: b))),
          ));
        }
      }
    }

    if (_selectedFilter == "Tümü" || _selectedFilter == "Derslikler") {
      final classrooms = data['classrooms'] as List? ?? [];
      for (var c in classrooms) {
        if (c['name'].toLowerCase().contains(query) || c['building'].toLowerCase().contains(query)) {
          results.add(InfoCard(
            title: c['name'], subtitle: c['building'], badge: const AppBadge(label: "Derslik"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroomData: c))),
          ));
        }
      }
    }

    if (_selectedFilter == "Tümü" || _selectedFilter == "Hocalar") {
      final instructors = data['instructors'] as List? ?? [];
      for (var i in instructors) {
        if (i['name'].toLowerCase().contains(query) || i['department'].toLowerCase().contains(query)) {
          results.add(InfoCard(
            title: i['name'], subtitle: i['department'], badge: const AppBadge(label: "Hoca"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InstructorDetailScreen(instructorData: i))),
          ));
        }
      }
    }

    if (_selectedFilter == "Tümü" || _selectedFilter == "Etkinlikler") {
      final events = data['events'] as List? ?? [];
      for (var e in events) {
        if (e['title'].toLowerCase().contains(query) || e['description'].toLowerCase().contains(query)) {
          results.add(InfoCard(
            title: e['title'], subtitle: e['date'], badge: const AppBadge(label: "Etkinlik"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventData: e))),
          ));
        }
      }
    }

    return results;
  }
}