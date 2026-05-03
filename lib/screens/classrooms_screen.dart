import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
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
    "Amphitheater",
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
    if (text.contains("Floor") || text.contains("Kat")) return text;

    final number = int.tryParse(text);
    if (number == -1) return "Basement";
    if (number == 0) return "Ground Floor";
    if (number != null) return "Floor $number";

    return text;
  }

  int _floorOrder(String label) {
    if (label == "Basement") return -1;
    if (label == "Ground Floor") return 0;
    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match == null) return 999;
    return int.tryParse(match.group(1) ?? "999") ?? 999;
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
            final floorSet = <String>{};

            for (final c in allClassrooms) {
              floorSet.add(_floorLabel(c['floorLabel'] ?? c['floor']));
            }

            final sortedFloors = floorSet.toList()
              ..sort((a, b) => _floorOrder(a).compareTo(_floorOrder(b)));

            final floorFilters = ["All Floors", ...sortedFloors];

            final filteredClassrooms = allClassrooms.where((classroom) {
              final name = classroom['name']?.toString() ?? "";
              final building = classroom['building']?.toString() ?? "";
              final type = classroom['type']?.toString() ?? "";
              final floor = classroom['floorLabel'] ?? classroom['floor'] ?? 0;

              final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  building.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesType = _selectedTypeFilter == "All" || type == _selectedTypeFilter;
              final matchesFloor = _selectedFloorFilter == "All Floors" || _floorLabel(floor) == _selectedFloorFilter;

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
                      return AppFilterChip(
                        label: _typeFilters[index],
                        active: _selectedTypeFilter == _typeFilters[index],
                        onTap: () => setState(() => _selectedTypeFilter = _typeFilters[index]),
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
                      return AppFilterChip(
                        label: floorFilters[index],
                        active: _selectedFloorFilter == floorFilters[index],
                        onTap: () => setState(() => _selectedFloorFilter = floorFilters[index]),
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
                        "No classrooms found matching your filters.",
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

                      return InfoCard(
                        title: safeClassroomData['name']?.toString() ?? "",
                        subtitle: safeClassroomData['building']?.toString() ?? "",
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