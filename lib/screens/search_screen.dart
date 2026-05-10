import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart';

// Import detail screens for navigation
import 'building_detail_screen.dart';
import 'classroom_detail_screen.dart';
import 'instructor_detail_screen.dart';
import 'event_detail_screen.dart';
import 'announcements_screen.dart';
import 'cafeteria_menu_screen.dart';
import 'office_hours_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _filters = [
    "All",
    "Buildings",
    "Classrooms",
    "Instructors",
    "Events",
    "Announcements",
    "Cafeteria",
    "Office Hours",
  ];
  final List<String> _recentSearches = ["FE-101", "Library", "John Doe", "Spring Festival"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  // Helper: Safely lowercase any value (handles null)
  String _lower(dynamic value) {
    return value?.toString().toLowerCase() ?? "";
  }

  // Helper: Check if any field contains the query
  bool _matches(String query, List<dynamic> fields) {
    return fields.any((field) => _lower(field).contains(query));
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
                      placeholder: "Search on campus...",
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
          const Text("Recent Searches", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
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
          const Text("No results found", style: TextStyle(fontSize: 18, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  List<Widget> _buildSearchResults(Map<String, dynamic> data) {
    List<Widget> results = [];
    final query = _searchQuery.toLowerCase();

    // BUILDINGS (campus units / faculties / campus guide items)
    if (_selectedFilter == "All" || _selectedFilter == "Buildings") {
      final buildings = data['buildings'] as List? ?? [];
      for (var b in buildings) {
        if (_matches(query, [b['name'], b['abbr'], b['location']])) {
          results.add(InfoCard(
            title: b['name']?.toString() ?? '',
            subtitle: b['location']?.toString() ?? '',
            badge: const AppBadge(label: "Building"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BuildingDetailScreen(buildingData: b))),
          ));
        }
      }
    }

    // CLASSROOMS
    if (_selectedFilter == "All" || _selectedFilter == "Classrooms") {
      final classrooms = data['classrooms'] as List? ?? [];
      for (var c in classrooms) {
        if (_matches(query, [c['name'], c['building'], c['campus'], c['location']])) {
          results.add(InfoCard(
            title: c['name']?.toString() ?? '',
            subtitle: c['building']?.toString() ?? '',
            badge: const AppBadge(label: "Classroom"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroomData: c))),
          ));
        }
      }
    }

    // INSTRUCTORS
    if (_selectedFilter == "All" || _selectedFilter == "Instructors") {
      final instructors = data['instructors'] as List? ?? [];
      for (var i in instructors) {
        if (_matches(query, [i['name'], i['department'], i['title']])) {
          results.add(InfoCard(
            title: i['name']?.toString() ?? '',
            subtitle: i['department']?.toString() ?? '',
            badge: const AppBadge(label: "Instructor"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InstructorDetailScreen(instructorData: i))),
          ));
        }
      }
    }

    // EVENTS
    if (_selectedFilter == "All" || _selectedFilter == "Events") {
      final events = data['events'] as List? ?? [];
      for (var e in events) {
        if (_matches(query, [e['title'], e['description'], e['location'], e['category']])) {
          results.add(InfoCard(
            title: e['title']?.toString() ?? '',
            subtitle: e['date']?.toString() ?? '',
            badge: const AppBadge(label: "Event"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventData: e))),
          ));
        }
      }
    }

    // ANNOUNCEMENTS
    if (_selectedFilter == "All" || _selectedFilter == "Announcements") {
      final announcements = data['announcements'] as List? ?? [];
      for (var a in announcements) {
        if (_matches(query, [a['title'], a['content'], a['category']])) {
          results.add(InfoCard(
            title: a['title']?.toString() ?? '',
            subtitle: a['date']?.toString() ?? a['publishDate']?.toString() ?? '',
            metadata: a['content']?.toString() ?? '',
            badge: const AppBadge(label: "Announcement"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
          ));
        }
      }
    }

    // CAFETERIA / FOOD
    if (_selectedFilter == "All" || _selectedFilter == "Cafeteria") {
      final cafeteriaData = data['cafeteria'] as Map<dynamic, dynamic>? ?? {};
      final menus = cafeteriaData['menus'] as Map<dynamic, dynamic>? ?? {};

      menus.forEach((mealType, menu) {
        if (menu is! Map) return;

        final menuName = menu['menuName']?.toString() ?? '';
        final items = menu['items'] as List<dynamic>? ?? [];

        // Check if mealType, menuName, or any item name matches
        final itemNames = items.map((item) {
          if (item is Map) return item['name']?.toString() ?? '';
          return item.toString();
        }).toList();

        final allFields = [mealType.toString(), menuName, ...itemNames];

        if (_matches(query, allFields)) {
          final itemList = itemNames.where((n) => n.isNotEmpty).take(3).join(", ");

          results.add(InfoCard(
            title: menuName.isNotEmpty ? menuName : mealType.toString(),
            subtitle: "${menu['time'] ?? ''} • ${menu['price'] ?? ''}",
            metadata: itemList.isNotEmpty ? itemList : null,
            badge: const AppBadge(label: "Cafeteria"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen())),
          ));
        }
      });
    }

    // OFFICE HOURS
    if (_selectedFilter == "All" || _selectedFilter == "Office Hours") {
      final instructors = data['instructors'] as List? ?? [];
      for (var i in instructors) {
        final officeHours = i['officeHours'];
        final hoursList = officeHours is List ? officeHours.join(", ") : "";

        if (hoursList.isEmpty) continue;

        if (_matches(query, [i['name'], i['department'], hoursList, i['office']])) {
          results.add(InfoCard(
            title: i['name']?.toString() ?? '',
            subtitle: hoursList,
            metadata: i['department']?.toString() ?? '',
            badge: const AppBadge(label: "Office Hours"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficeHoursScreen())),
          ));
        }
      }
    }

    return results;
  }
}