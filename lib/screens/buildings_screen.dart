import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/mock_data.dart';
import 'building_detail_screen.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({Key? key}) : super(key: key);

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";

  final List<String> _filters = ["Tümü", "Akademik", "İdari", "Sosyal"];

  @override
  Widget build(BuildContext context) {
    final filteredBuildings = MockData.buildings.where((b) {
      final matchesSearch = b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.abbr.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == "Tümü" ||
          (_selectedFilter == "Akademik" && b.type == "academic") ||
          (_selectedFilter == "İdari" && b.type == "admin") ||
          (_selectedFilter == "Sosyal" && b.type == "social");
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: "Binalar"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppSearchBar(
              placeholder: "Bina ara...",
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text("Kampüs haritasını görüntüle", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text("Haritayı Aç", style: TextStyle(color: AppTheme.primaryColor)),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredBuildings.length,
              itemBuilder: (context, index) {
                final b = filteredBuildings[index];
                return InfoCard(
                  title: b.name,
                  subtitle: b.location,
                  badge: AppBadge(label: b.abbr),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BuildingDetailScreen(building: b))
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