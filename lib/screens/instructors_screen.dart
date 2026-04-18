import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/mock_data.dart';
import 'instructor_detail_screen.dart';

class InstructorsScreen extends StatefulWidget {
  const InstructorsScreen({Key? key}) : super(key: key);

  @override
  State<InstructorsScreen> createState() => _InstructorsScreenState();
}

class _InstructorsScreenState extends State<InstructorsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";

  final List<String> _filters = ["Tümü", "Mühendislik", "İktisat", "Fen-Edebiyat"];

  @override
  Widget build(BuildContext context) {
    final filteredInstructors = MockData.instructors.where((i) {
      final matchesSearch = i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.department.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = _selectedFilter == "Tümü";
      if (_selectedFilter == "Mühendislik" && i.filter == "engineering") matchesFilter = true;
      if (_selectedFilter == "İktisat" && i.filter == "economics") matchesFilter = true;
      if (_selectedFilter == "Fen-Edebiyat" && i.filter == "science") matchesFilter = true;

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: "Öğretim Görevlileri", showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppSearchBar(
              placeholder: "Hoca veya bölüm ara...",
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
              itemCount: filteredInstructors.length,
              itemBuilder: (context, index) {
                final instructor = filteredInstructors[index];
                return InfoCard(
                  title: instructor.name,
                  subtitle: instructor.department,
                  metadata: "Ofis: ${instructor.office}",
                  badge: AppBadge(label: instructor.title),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => InstructorDetailScreen(instructor: instructor))
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