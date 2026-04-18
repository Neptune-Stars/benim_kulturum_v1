import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/mock_data.dart';
import 'classroom_detail_screen.dart';

class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen({Key? key}) : super(key: key);

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";

  final List<String> _filters = ["Tümü", "Derslik", "Amfi", "Laboratuvar"];

  @override
  Widget build(BuildContext context) {
    final filteredClassrooms = MockData.classrooms.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.building.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == "Tümü" || c.type == _selectedFilter;
      return matchesSearch && matchesFilter;
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
              itemCount: filteredClassrooms.length,
              itemBuilder: (context, index) {
                final c = filteredClassrooms[index];
                return InfoCard(
                  title: c.name,
                  subtitle: c.building,
                  metadata: "Kapasite: ${c.capacity} Kişi",
                  badge: AppBadge(label: c.type),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroom: c))
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
