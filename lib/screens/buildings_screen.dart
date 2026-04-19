import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart'; // MOCK DATA YERİNE JSON SERVİSİ
import 'building_detail_screen.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({Key? key}) : super(key: key);

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";
  late Future<Map<String, dynamic>> _databaseFuture; // JSON Future

  final List<String> _filters = ["Tümü", "Akademik", "İdari", "Sosyal"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase(); // Veriyi çekmeye başla
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Binalar"),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _databaseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Bina verisi bulunamadı."));
          }

          final allBuildings = snapshot.data!['buildings'] as List<dynamic>? ?? [];

          // Map üzerinden filtreleme yapıyoruz
          final filteredBuildings = allBuildings.where((b) {
            final name = b['name']?.toString() ?? "";
            final abbr = b['abbr']?.toString() ?? "";
            final type = b['type']?.toString() ?? "";

            final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                abbr.toLowerCase().contains(_searchQuery.toLowerCase());

            final matchesFilter = _selectedFilter == "Tümü" ||
                (_selectedFilter == "Akademik" && type == "academic") ||
                (_selectedFilter == "İdari" && type == "admin") ||
                (_selectedFilter == "Sosyal" && type == "social");

            return matchesSearch && matchesFilter;
          }).toList();

          return Column(
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
                      title: b['name'] ?? "",
                      subtitle: b['location'] ?? "",
                      badge: AppBadge(label: b['abbr'] ?? ""),
                      onTap: () => Navigator.push(
                          context,
                          // Artık modele değil, Map objesine (b) gönderiyoruz
                          MaterialPageRoute(builder: (_) => BuildingDetailScreen(buildingData: b))
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}