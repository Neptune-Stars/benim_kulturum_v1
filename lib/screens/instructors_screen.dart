import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart';
import 'instructor_detail_screen.dart';

class InstructorsScreen extends StatefulWidget {
  const InstructorsScreen({Key? key}) : super(key: key);

  @override
  State<InstructorsScreen> createState() => _InstructorsScreenState();
}

class _InstructorsScreenState extends State<InstructorsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _filters = [
    "Tümü",
    "Mühendislik",
    "İktisat",
    "Fen-Edebiyat",
    "Hukuk",
    "Mimarlık",
    "Psikoloji",
    "Edebiyat"
  ];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Öğretim Görevlileri", showBack: true),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Hoca verisi bulunamadı."));
            }

            final allInstructors = snapshot.data!['instructors'] as List<dynamic>? ?? [];

            final filteredInstructors = allInstructors.where((i) {
              final name = i['name']?.toString() ?? "";
              final dept = i['department']?.toString() ?? "";
              final filterValue = i['filter']?.toString() ?? "";

              final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  dept.toLowerCase().contains(_searchQuery.toLowerCase());

              bool matchesFilter = _selectedFilter == "Tümü";

              if (_selectedFilter == "Mühendislik" && filterValue == "engineering") matchesFilter = true;
              if (_selectedFilter == "İktisat" && filterValue == "economics") matchesFilter = true;
              if (_selectedFilter == "Fen-Edebiyat" && filterValue == "science") matchesFilter = true;
              if (_selectedFilter == "Hukuk" && filterValue == "law") matchesFilter = true;
              if (_selectedFilter == "Mimarlık" && filterValue == "architecture") matchesFilter = true;
              if (_selectedFilter == "Psikoloji" && filterValue == "psychology") matchesFilter = true;
              if (_selectedFilter == "Edebiyat" && filterValue == "literature") matchesFilter = true;

              return matchesSearch && matchesFilter;
            }).toList();

            return Column(
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

                      // HATA ÇÖZÜMÜ: Map türünü güvenli bir şekilde String key'lere dönüştürüyoruz (Casting)
                      final Map<String, dynamic> safeInstructorData = Map<String, dynamic>.from(instructor as Map);

                      return InfoCard(
                        title: safeInstructorData['name'] ?? '',
                        subtitle: safeInstructorData['department'] ?? '',
                        metadata: "Ofis: ${safeInstructorData['office']}",
                        badge: AppBadge(label: safeInstructorData['title'] ?? ''),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => InstructorDetailScreen(instructorData: safeInstructorData))
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