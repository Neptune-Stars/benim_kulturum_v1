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
  String _selectedFilter = "Tümü";
  late Future<Map<String, dynamic>> _databaseFuture; // JSON Future

  final List<String> _filters = ["Tümü", "Derslik", "Amfi", "Laboratuvar"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
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
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Derslik verisi bulunamadı."));
          }

          final allClassrooms = snapshot.data!['classrooms'] as List<dynamic>? ?? [];

          // Map üzerinden filtreleme yapıyoruz
          final filteredClassrooms = allClassrooms.where((c) {
            final name = c['name']?.toString() ?? "";
            final building = c['building']?.toString() ?? "";
            final type = c['type']?.toString() ?? "";

            final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                building.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesFilter = _selectedFilter == "Tümü" || type == _selectedFilter;

            return matchesSearch && matchesFilter;
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
                child: filteredClassrooms.isEmpty
                    ? const Center(child: Text("Aramanıza uygun derslik bulunamadı.", style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredClassrooms.length,
                  itemBuilder: (context, index) {
                    final c = filteredClassrooms[index];
                    return InfoCard(
                      title: c['name'] ?? "",
                      subtitle: c['building'] ?? "",
                      metadata: "Kapasite: ${c['capacity']} Kişi",
                      badge: AppBadge(label: c['type'] ?? ""),
                      onTap: () => Navigator.push(
                          context,
                          // Artık modele değil, Map objesine (c) gönderiyoruz
                          MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroomData: c))
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