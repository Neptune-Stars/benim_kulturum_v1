import 'package:flutter/material.dart';

import '../data/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/badge_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/search_bar_widget.dart';

import 'announcements_screen.dart';
import 'building_detail_screen.dart';
import 'cafeteria_menu_screen.dart';
import 'classroom_detail_screen.dart';
import 'event_detail_screen.dart';
import 'instructor_detail_screen.dart';
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

  @override
  void initState() {
    super.initState();

    // Search should reflect the current Firestore state, not old cached data.
    _databaseFuture = DataService.loadDatabase(forceRefresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _toStringDynamicMap(Map<dynamic, dynamic> source) {
    return source.map(
          (key, value) => MapEntry(key.toString(), value),
    );
  }

  String _normalize(dynamic value) {
    return value
        ?.toString()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim() ??
        "";
  }

  bool _matches(String query, List<dynamic> fields) {
    return fields.any((field) => _normalize(field).contains(query));
  }

  String _campusKey(dynamic value) {
    return _normalize(
      DataService.normalizeCampusKey(value?.toString()),
    );
  }

  String _buildingCampus(Map<dynamic, dynamic> building) {
    final campus = building['campus'] ??
        building['campusKey'] ??
        building['campusDisplayName'];

    if (campus != null && campus.toString().trim().isNotEmpty) {
      return campus.toString();
    }

    final location = building['location']?.toString() ?? '';

    if (location.contains(',')) {
      return location.split(',').first.trim();
    }

    return location;
  }

  String _classroomCampus(Map<dynamic, dynamic> classroom) {
    final campus = classroom['campus'] ??
        classroom['campusKey'] ??
        classroom['campusDisplayName'];

    if (campus != null && campus.toString().trim().isNotEmpty) {
      return campus.toString();
    }

    final building = classroom['building']?.toString() ?? '';

    if (building.contains(',')) {
      return building.split(',').first.trim();
    }

    return building;
  }

  String _buildingType(Map<dynamic, dynamic> building) {
    final rawType =
        building['typeNormalized'] ?? building['type'] ?? building['category'];

    return DataService.normalizeCampusUnitType(rawType?.toString());
  }

  bool _isClassroomLikeBuilding(Map<dynamic, dynamic> building) {
    final type = _buildingType(building);

    return type == 'Classroom' ||
        type == 'Laboratory' ||
        type == 'Computer Lab' ||
        type == 'Workshop' ||
        type == 'Hall' ||
        type == 'Auditorium' ||
        type == 'Seminar Hall' ||
        type == 'Conference Hall';
  }

  bool _isLibraryLikeBuilding(Map<dynamic, dynamic> building) {
    final type = _buildingType(building);
    final name = _normalize(building['name']);

    return type == 'Library' ||
        type == 'Study Area' ||
        name.contains('library') ||
        name.contains('kutuphane');
  }

  String _campusNameKey({
    required dynamic campus,
    required dynamic name,
  }) {
    return "${_campusKey(campus)}|${_normalize(name)}";
  }

  String _classroomResultKey(Map<dynamic, dynamic> classroom) {
    final campus = _classroomCampus(classroom);
    final name = classroom['name'];
    final building = classroom['building'] ?? classroom['location'];
    final floor = classroom['floorLabel'] ?? classroom['floor'];

    return "classroom|${_campusKey(campus)}|${_normalize(name)}|${_normalize(building)}|${_normalize(floor)}";
  }

  String _buildingResultKey(Map<dynamic, dynamic> building) {
    final campus = _buildingCampus(building);
    final type = _buildingType(building);
    final name = building['name'];
    final location = building['location'];

    // Same-campus library duplicate rule:
    // Example: "Ataköy Library" and "Central Library" should not both appear
    // if they represent the same campus library.
    if (_isLibraryLikeBuilding(building)) {
      return "building|${_campusKey(campus)}|library";
    }

    // Classroom-like records inside buildings are risky because the real
    // source should be classrooms collection.
    if (_isClassroomLikeBuilding(building)) {
      return "space|${_campusKey(campus)}|${_normalize(name)}";
    }

    return "building|${_campusKey(campus)}|${_normalize(type)}|${_normalize(name)}|${_normalize(location)}";
  }

  String _instructorKey(Map<dynamic, dynamic> instructor) {
    return "instructor|${instructor['firestoreDocId'] ?? instructor['id'] ?? _normalize(instructor['name'])}";
  }

  String _eventKey(Map<dynamic, dynamic> event) {
    return "event|${event['firestoreDocId'] ?? event['id'] ?? '${_normalize(event['title'])}|${_normalize(event['date'])}'}";
  }

  String _announcementKey(Map<dynamic, dynamic> announcement) {
    return "announcement|${announcement['firestoreDocId'] ?? announcement['id'] ?? '${_normalize(announcement['title'])}|${_normalize(announcement['date'])}'}";
  }

  bool _addUniqueResult({
    required List<Widget> results,
    required Set<String> addedKeys,
    required String key,
    required Widget widget,
    List<String> aliases = const [],
  }) {
    final allKeys = [
      key,
      ...aliases,
    ].where((item) => item.trim().isNotEmpty).toList();

    if (allKeys.any(addedKeys.contains)) {
      return false;
    }

    addedKeys.addAll(allKeys);
    results.add(widget);

    return true;
  }

  Widget _buildRecentSearches() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          "Search for classrooms, instructors, events, announcements, cafeteria information, or campus locations.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: mutedColor,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: mutedColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No results found",
            style: TextStyle(
              fontSize: 18,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSearchResults(Map<String, dynamic> data) {
    final results = <Widget>[];
    final addedKeys = <String>{};

    final query = _normalize(_searchQuery);

    final buildings = (data['buildings'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .where((building) {
      if (DataService.isDeletedRecord(building)) return false;
      if (building['isVisible'] == false) return false;
      return true;
    }).toList();

    final classrooms = (data['classrooms'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .where((classroom) => !DataService.isDeletedRecord(classroom))
        .toList();

    final classroomCampusNameKeys = classrooms.map((classroom) {
      return _campusNameKey(
        campus: _classroomCampus(classroom),
        name: classroom['name'],
      );
    }).toSet();

    final visibleBuildingCampusNameKeys = <String>{};

    // BUILDINGS / CAMPUS UNITS
    if (_selectedFilter == "All" || _selectedFilter == "Buildings") {
      for (final building in buildings) {
        if (!_matches(query, [
          building['name'],
          building['abbr'],
          building['location'],
          building['type'],
          building['typeNormalized'],
          building['category'],
          building['campus'],
          building['campusDisplayName'],
        ])) {
          continue;
        }

        final campus = _buildingCampus(building);
        final name = building['name'];

        final campusNameKey = _campusNameKey(
          campus: campus,
          name: name,
        );

        // If a classroom/lab/amfi-like record exists in buildings and the same
        // place also exists in classrooms, do not show it again as Building.
        if (_isClassroomLikeBuilding(building) &&
            classroomCampusNameKeys.contains(campusNameKey)) {
          continue;
        }

        final resultKey = _buildingResultKey(building);

        final added = _addUniqueResult(
          results: results,
          addedKeys: addedKeys,
          key: resultKey,
          aliases: [
            "location|$campusNameKey",
          ],
          widget: InfoCard(
            title: building['name']?.toString() ?? '',
            subtitle: building['location']?.toString() ??
                building['campusDisplayName']?.toString() ??
                '',
            badge: const AppBadge(label: "Building"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BuildingDetailScreen(
                  buildingData: _toStringDynamicMap(building),
                ),
              ),
            ),
          ),
        );

        if (added) {
          visibleBuildingCampusNameKeys.add(campusNameKey);

          if (_isLibraryLikeBuilding(building)) {
            visibleBuildingCampusNameKeys.add(
              "${_campusKey(campus)}|library",
            );
          }
        }
      }
    }

    // CLASSROOMS
    if (_selectedFilter == "All" || _selectedFilter == "Classrooms") {
      for (final classroom in classrooms) {
        if (!_matches(query, [
          classroom['name'],
          classroom['building'],
          classroom['campus'],
          classroom['location'],
          classroom['floorLabel'],
          classroom['type'],
        ])) {
          continue;
        }

        final campus = _classroomCampus(classroom);
        final name = classroom['name'];

        final campusNameKey = _campusNameKey(
          campus: campus,
          name: name,
        );

        // If the same real location has already been shown as a campus unit,
        // do not show it again as Classroom.
        // Example:
        // Ataköy Library -> Building
        // Ataköy Library -> Classroom
        if (visibleBuildingCampusNameKeys.contains(campusNameKey)) {
          continue;
        }

        final resultKey = _classroomResultKey(classroom);

        final subtitleParts = [
          classroom['campus'],
          classroom['location'],
          classroom['building'],
          classroom['floorLabel'] ?? classroom['floor'],
        ]
            .where(
              (value) =>
          value != null && value.toString().trim().isNotEmpty,
        )
            .map((value) => value.toString())
            .toSet()
            .toList();

        _addUniqueResult(
          results: results,
          addedKeys: addedKeys,
          key: resultKey,
          aliases: [
            "location|$campusNameKey",
          ],
          widget: InfoCard(
            title: classroom['name']?.toString() ?? '',
            subtitle: subtitleParts.join(", "),
            badge: const AppBadge(label: "Classroom"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClassroomDetailScreen(
                  classroomData: _toStringDynamicMap(classroom),
                ),
              ),
            ),
          ),
        );
      }
    }

    // INSTRUCTORS
    if (_selectedFilter == "All" || _selectedFilter == "Instructors") {
      final instructors = data['instructors'] as List? ?? [];

      for (final rawInstructor in instructors) {
        if (rawInstructor is! Map<dynamic, dynamic>) continue;
        if (DataService.isDeletedRecord(rawInstructor)) continue;

        if (!_matches(query, [
          rawInstructor['name'],
          rawInstructor['department'],
          rawInstructor['title'],
        ])) {
          continue;
        }

        _addUniqueResult(
          results: results,
          addedKeys: addedKeys,
          key: _instructorKey(rawInstructor),
          widget: InfoCard(
            title: rawInstructor['name']?.toString() ?? '',
            subtitle: rawInstructor['department']?.toString() ?? '',
            badge: const AppBadge(label: "Instructor"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InstructorDetailScreen(
                  instructorData: _toStringDynamicMap(rawInstructor),
                ),
              ),
            ),
          ),
        );
      }
    }

    // EVENTS
    if (_selectedFilter == "All" || _selectedFilter == "Events") {
      final events = data['events'] as List? ?? [];

      for (final rawEvent in events) {
        if (rawEvent is! Map<dynamic, dynamic>) continue;
        if (DataService.isDeletedRecord(rawEvent)) continue;

        if (!_matches(query, [
          rawEvent['title'],
          rawEvent['description'],
          rawEvent['location'],
          rawEvent['category'],
        ])) {
          continue;
        }

        _addUniqueResult(
          results: results,
          addedKeys: addedKeys,
          key: _eventKey(rawEvent),
          widget: InfoCard(
            title: rawEvent['title']?.toString() ?? '',
            subtitle: rawEvent['date']?.toString() ?? '',
            badge: const AppBadge(label: "Event"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailScreen(
                  eventData: _toStringDynamicMap(rawEvent),
                ),
              ),
            ),
          ),
        );
      }
    }

    // ANNOUNCEMENTS
    if (_selectedFilter == "All" || _selectedFilter == "Announcements") {
      final announcements = data['announcements'] as List? ?? [];

      for (final rawAnnouncement in announcements) {
        if (rawAnnouncement is! Map<dynamic, dynamic>) continue;
        if (DataService.isDeletedRecord(rawAnnouncement)) continue;

        if (!_matches(query, [
          rawAnnouncement['title'],
          rawAnnouncement['content'],
          rawAnnouncement['category'],
        ])) {
          continue;
        }

        _addUniqueResult(
          results: results,
          addedKeys: addedKeys,
          key: _announcementKey(rawAnnouncement),
          widget: InfoCard(
            title: rawAnnouncement['title']?.toString() ?? '',
            subtitle: rawAnnouncement['date']?.toString() ??
                rawAnnouncement['publishDate']?.toString() ??
                '',
            metadata: rawAnnouncement['content']?.toString() ?? '',
            badge: const AppBadge(label: "Announcement"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AnnouncementsScreen(),
              ),
            ),
          ),
        );
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

        final itemNames = items.map((item) {
          if (item is Map) {
            return item['name']?.toString() ?? '';
          }

          return item.toString();
        }).toList();

        final allFields = [
          mealType.toString(),
          menuName,
          ...itemNames,
        ];

        if (!_matches(query, allFields)) return;

        final itemList = itemNames
            .where((name) => name.isNotEmpty)
            .take(3)
            .join(", ");

        _addUniqueResult(
          results: results,
          addedKeys: addedKeys,
          key: "cafeteria|${_normalize(mealType)}|${_normalize(menuName)}",
          widget: InfoCard(
            title: menuName.isNotEmpty ? menuName : mealType.toString(),
            subtitle: "${menu['time'] ?? ''} • ${menu['price'] ?? ''}",
            metadata: itemList.isNotEmpty ? itemList : null,
            badge: const AppBadge(label: "Cafeteria"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CafeteriaMenuScreen(),
              ),
            ),
          ),
        );
      });
    }

    // OFFICE HOURS
    if (_selectedFilter == "All" || _selectedFilter == "Office Hours") {
      final instructors = data['instructors'] as List? ?? [];

      for (final rawInstructor in instructors) {
        if (rawInstructor is! Map<dynamic, dynamic>) continue;
        if (DataService.isDeletedRecord(rawInstructor)) continue;

        final officeHours = rawInstructor['officeHours'];
        final hoursList = officeHours is List ? officeHours.join(", ") : "";

        if (hoursList.trim().isEmpty) continue;

        final primaryInstructorMatches = _matches(query, [
          rawInstructor['name'],
          rawInstructor['department'],
          rawInstructor['title'],
        ]);

        final officeHourMatches = _matches(query, [
          hoursList,
          rawInstructor['office'],
        ]);

        // Avoid showing the same instructor twice when user searches by name.
        // Office Hours result should appear only when the query targets office/hour info.
        if (!officeHourMatches || primaryInstructorMatches) {
          continue;
        }

        _addUniqueResult(
          results: results,
          addedKeys: addedKeys,
          key: "office-hours|${_instructorKey(rawInstructor)}",
          widget: InfoCard(
            title: rawInstructor['name']?.toString() ?? '',
            subtitle: hoursList,
            metadata: rawInstructor['department']?.toString() ?? '',
            badge: const AppBadge(label: "Office Hours"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OfficeHoursScreen(),
              ),
            ),
          ),
        );
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = _searchQuery.trim();

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
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
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
              child: trimmedQuery.isEmpty
                  ? _buildRecentSearches()
                  : FutureBuilder<Map<String, dynamic>>(
                future: _databaseFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return _buildEmptyState();
                  }

                  final searchResults =
                  _buildSearchResults(snapshot.data!);

                  return searchResults.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
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
}