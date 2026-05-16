import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../data/data_service.dart';
import 'classroom_detail_screen.dart';

class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen({Key? key}) : super(key: key);

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  String _searchQuery = "";
  String _selectedTypeFilter = "All";
  String _selectedFloorFilter = "All Floors";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _typeFilters = [
    "All",
    "Classroom",
    "Lecture Hall",
    "Laboratory",
  ];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  String _floorLabel(dynamic floor) {
    final text = floor?.toString().trim() ?? "";
    if (text.isEmpty) return "No Floor Info";

    final normalized = text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (compact == 'b1b2' ||
        compact == 'b2b1' ||
        normalized.contains('b1 and b2') ||
        normalized.contains('b1 / b2') ||
        normalized.contains('b1-b2')) {
      return "B1-B2 Floors";
    }

    if (compact == 'b2' || compact == 'b2floor') return "B2 Floor";
    if (compact == 'b1' || compact == 'b1floor') return "B1 Floor";

    if (normalized == 'basement' || normalized == 'basement floor') {
      return "Basement Floor";
    }
    if (normalized == 'ground' || normalized == 'ground floor') {
      return "Ground Floor";
    }
    if (normalized == 'entrance' || normalized == 'entrance floor') {
      return "Entrance Floor";
    }
    if (normalized == 'mezzanine' || normalized == 'mezzanine floor') {
      return "Mezzanine Floor";
    }

    if (text.contains("Floor")) return text;

    final number = int.tryParse(text);
    if (number == -2) return "B2 Floor";
    if (number == -1) return "Basement Floor";
    if (number == 0) return "Ground Floor";
    if (number != null && number > 0) return "${number}th Floor";

    return text;
  }

  List<String> _floorFilterLabels(dynamic floor) {
    final label = _floorLabel(floor);
    if (label == "B1-B2 Floors") {
      return ["B1 Floor", "B2 Floor"];
    }
    return [label];
  }

  int _floorOrder(String label) {
    switch (label) {
      case "B2 Floor":
        return -20;
      case "B1 Floor":
        return -10;
      case "B1-B2 Floors":
        return -9;
      case "Basement Floor":
        return -5;
      case "Ground Floor":
        return 0;
      case "Entrance Floor":
        return 1;
      case "Mezzanine Floor":
        return 2;
      case "No Floor Info":
        return 999;
    }

    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match == null) return 998;

    return (int.tryParse(match.group(1) ?? "99") ?? 99) * 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Classrooms", showBack: true),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!['classrooms'] == null) {
              return const Center(child: Text("Classroom data not found."));
            }

            final allClassrooms = snapshot.data!['classrooms'] as List<dynamic>? ?? [];

            final floorSet = <String>{"B2 Floor", "B1 Floor"};

            for (final c in allClassrooms) {
              floorSet.addAll(_floorFilterLabels(c['floorLabel'] ?? c['floor']));
            }

            final sortedFloors = floorSet.toList()
              ..sort((a, b) => _floorOrder(a).compareTo(_floorOrder(b)));

            final floorFilters = [
              "All Floors",
              ...sortedFloors,
            ];

            final filteredClassrooms = allClassrooms.where((classroom) {
              final String name = (classroom['name'] ?? "").toString();
              final String campus = (classroom['campus'] ?? "").toString();
              final String location = (classroom['location'] ?? "").toString();
              final String building = (classroom['building'] ?? "").toString();
              final String rawType = (classroom['type'] ?? "").toString();
              final List<String> unitsKeywords = [
                'Library', 'Kütüphane', 'Canteen', 'Kantin', 'Health Unit',
                'Revir', 'Student Affairs', 'Öğrenci İşleri', 'Dining', 'Cafeteria'
              ];

              bool isUnitEntity = unitsKeywords.any((k) => name.contains(k));
              if (isUnitEntity) return false;

              final displayType = rawType == "Amphitheater" ? "Lecture Hall" : rawType;

              final validEducationTypes = ["Classroom", "Lecture Hall", "Laboratory", "Amphitheater"];
              if (!validEducationTypes.contains(displayType) && _selectedTypeFilter == "All") {
                return false;
              }

              final floor = classroom['floorLabel'] ?? classroom['floor'];
              final floorLabels = _floorFilterLabels(floor);

              final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  campus.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  building.toLowerCase().contains(_searchQuery.toLowerCase());

              final matchesType = _selectedTypeFilter == "All" || displayType == _selectedTypeFilter;

              final matchesFloor = _selectedFloorFilter == "All Floors" || floorLabels.contains(_selectedFloorFilter);

              return matchesSearch && matchesType && matchesFloor;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppSearchBar(
                    placeholder: "Search classroom or building...",
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _typeFilters.length,
                    itemBuilder: (context, index) {
                      final filter = _typeFilters[index];
                      return AppFilterChip(
                        label: filter,
                        active: _selectedTypeFilter == filter,
                        onTap: () => setState(() => _selectedTypeFilter = filter),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: floorFilters.length,
                    itemBuilder: (context, index) {
                      final filter = floorFilters[index];
                      return AppFilterChip(
                        label: filter,
                        active: _selectedFloorFilter == filter,
                        onTap: () => setState(() => _selectedFloorFilter = filter),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: filteredClassrooms.isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        "No classroom found matching your filters.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                      ),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredClassrooms.length,
                    itemBuilder: (context, index) {
                      final classroom = filteredClassrooms[index];
                      final Map<String, dynamic> safeClassroomData = Map<String, dynamic>.from(classroom as Map);

                      final String campusInfo = safeClassroomData['campus']?.toString() ?? "";
                      final String locationInfo = safeClassroomData['location'] ?? safeClassroomData['building'] ?? "";

                      return InfoCard(
                        title: safeClassroomData['name']?.toString() ?? "",
                        subtitle: campusInfo.isNotEmpty ? "$campusInfo • $locationInfo" : locationInfo,
                        metadata: "Capacity: ${safeClassroomData['capacity'] ?? 0} People • Floor: ${_floorLabel(safeClassroomData['floorLabel'] ?? safeClassroomData['floor'])}",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroomData: safeClassroomData)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
      ),
    );
  }
}