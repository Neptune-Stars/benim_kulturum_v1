import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart'; // MOCK DATA YERİNE JSON SERVİSİ
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

  final List<String> _typeFilters = [
    "Tümü",
    "Derslik",
    "Amfi",
    "Laboratuvar",
  ];

  String _floorLabel(int floor) => "$floor. Kat";

  @override
  Widget build(BuildContext context) {
    final floorFilters = [
      "Tüm Katlar",
      ...{
        ...MockData.classrooms.map((c) => _floorLabel(c.floor)),
      }.toList()
        ..sort((a, b) {
          if (a == "Tüm Katlar") return -1;
          if (b == "Tüm Katlar") return 1;
          final aNum = int.parse(a.split('.').first);
          final bNum = int.parse(b.split('.').first);
          return aNum.compareTo(bNum);
        }),
    ];

    final filteredClassrooms = MockData.classrooms.where((classroom) {
      final matchesSearch =
          classroom.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              classroom.building.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesType = _selectedTypeFilter == "Tümü" ||
          classroom.type == _selectedTypeFilter;

      final matchesFloor = _selectedFloorFilter == "Tüm Katlar" ||
          _floorLabel(classroom.floor) == _selectedFloorFilter;

      return matchesSearch && matchesType && matchesFloor;
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: "Derslikler", showBack: true),
      body: Column(
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
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 16,
                  ),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredClassrooms.length,
              itemBuilder: (context, index) {
                final classroom = filteredClassrooms[index];

                return InfoCard(
                  title: classroom.name,
                  subtitle: classroom.building,
                  metadata:
                  "Kapasite: ${classroom.capacity} Kişi • Kat: ${classroom.floor}",
                  badge: AppBadge(label: classroom.type),
                  onTap: () {
                    // Burada varsa detail ekranına gidebilir
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}