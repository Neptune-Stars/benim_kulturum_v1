import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart'; // MOCK DATA YERİNE JSON SERVİSİ GELDİ

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";
  late Future<Map<String, dynamic>> _databaseFuture; // JSON verisini tutacak değişken

  final List<String> _filters = ["Tümü", "Akademik", "İdari", "Burs", "Genel"];

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında veriyi asenkron olarak çekmeye başla
    _databaseFuture = DataService.loadDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Duyurular"),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _databaseFuture,
        builder: (context, snapshot) {
          // 1. Veri Yükleniyor Durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Hata Durumu
          if (snapshot.hasError) {
            return Center(child: Text("Veri yüklenemedi: ${snapshot.error}"));
          }

          // 3. Veri Boş Durumu
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Gösterilecek duyuru bulunamadı."));
          }

          // JSON verisinden duyurular listesini çekiyoruz
          final allAnnouncements = snapshot.data!['announcements'] as List<dynamic>? ?? [];

          // Arama ve filtreleme işlemini artık JSON objelerine (Map) göre yapıyoruz
          final filteredAnnouncements = allAnnouncements.where((a) {
            final title = a['title']?.toString() ?? "";
            final content = a['content']?.toString() ?? "";
            final category = a['category']?.toString() ?? "";

            final matchesSearch = title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                content.toLowerCase().contains(_searchQuery.toLowerCase());

            final mappedFilter = _selectedFilter == "Akademik" ? "academic" :
            _selectedFilter == "İdari" ? "admin" :
            _selectedFilter == "Burs" ? "scholarship" :
            _selectedFilter == "Genel" ? "general" : "Tümü";

            final matchesFilter = _selectedFilter == "Tümü" || category == mappedFilter;
            return matchesSearch && matchesFilter;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppSearchBar(
                  placeholder: "Duyuru ara...",
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
                child: filteredAnnouncements.isEmpty
                    ? const Center(child: Text("Aramanıza uygun duyuru bulunamadı.", style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredAnnouncements.length,
                  itemBuilder: (context, index) {
                    final a = filteredAnnouncements[index];
                    return InfoCard(
                      title: a['title'] ?? "",
                      subtitle: a['content'] ?? "",
                      metadata: a['date'] ?? "",
                      showChevron: false,
                      badge: a['isNew'] == true // isNew değerini JSON'dan okuyoruz
                          ? const AppBadge(label: "Yeni", backgroundColor: AppTheme.primaryColor, textColor: Colors.white)
                          : null,
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