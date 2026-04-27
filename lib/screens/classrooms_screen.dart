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
  String _selectedTypeFilter = "Tümü";
  String _selectedFloorFilter = "Tüm Katlar";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _typeFilters = [
    "Tümü",
    "Derslik",
    "Amfi",
    "Laboratuvar",
  ];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  String _floorLabel(dynamic floor) {
    final text = floor?.toString().trim() ?? "";

    if (text.isEmpty) return "Kat Bilgisi Yok";
    if (text.contains("Kat")) return text;

    final number = int.tryParse(text);

    if (number == -1) return "Bodrum Kat";
    if (number == 0) return "Zemin Kat";
    if (number != null) return "$number. Kat";

    return text;
  }

  int _floorOrder(String label) {
    if (label == "Bodrum Kat") return -1;
    if (label == "Zemin Kat") return 0;

    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match == null) return 999;

    return int.tryParse(match.group(1) ?? "999") ?? 999;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Derslikler", showBack: true),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!['classrooms'] == null) {
              return const Center(child: Text("Derslik verisi bulunamadı."));
            }

            final allClassrooms = snapshot.data!['classrooms'] as List<dynamic>? ?? [];

            final floorSet = <String>{};

            for (final c in allClassrooms) {
              floorSet.add(_floorLabel(c['floorLabel'] ?? c['floor']));
            }

            final sortedFloors = floorSet.toList()
              ..sort((a, b) => _floorOrder(a).compareTo(_floorOrder(b)));

            final floorFilters = [
              "Tüm Katlar",
              ...sortedFloors,
            ];

            // Arama ve Filtreleme İşlemleri
            final filteredClassrooms = allClassrooms.where((classroom) {
              final name = classroom['name']?.toString() ?? "";
              final building = classroom['building']?.toString() ?? "";
              final type = classroom['type']?.toString() ?? "";
              final floor = classroom['floorLabel'] ?? classroom['floor'] ?? 0;

              final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  building.toLowerCase().contains(_searchQuery.toLowerCase());

              final matchesType = _selectedTypeFilter == "Tümü" || type == _selectedTypeFilter;

              final matchesFloor = _selectedFloorFilter == "Tüm Katlar" || _floorLabel(floor) == _selectedFloorFilter;

              return matchesSearch && matchesType && matchesFloor;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppSearchBar(
                    placeholder: "Derslik veya bina ara...",
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                // Tip filtreleri
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

                // Kat filtreleri
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
                        "Seçtiğin filtrelere uygun derslik bulunamadı.",
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

                      // HATA ÇÖZÜMÜ: Map türünü güvenli bir şekilde String key'lere dönüştürüyoruz (Casting)
                      final Map<String, dynamic> safeClassroomData = Map<String, dynamic>.from(classroom as Map);

                      return InfoCard(
                        title: safeClassroomData['name']?.toString() ?? "",
                        subtitle: safeClassroomData['building']?.toString() ?? "",
                        metadata: "Kapasite: ${safeClassroomData['capacity'] ?? 0} Kişi • Kat: ${_floorLabel(safeClassroomData['floorLabel'] ?? safeClassroomData['floor'])}",                        onTap: () => Navigator.push(
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