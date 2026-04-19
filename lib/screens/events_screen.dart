import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart'; // MOCK DATA YERİNE JSON SERVİSİ
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";
  late Future<Map<String, dynamic>> _databaseFuture; // JSON Future

  final List<String> _filters = ["Tümü", "Akademik", "Kültürel", "Spor", "Sosyal"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  String _getCategoryLabel(String cat) {
    switch(cat) {
      case "academic": return "Akademik";
      case "cultural": return "Kültürel";
      case "sports": return "Spor";
      case "social": return "Sosyal";
      default: return "Genel";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Etkinlikler", showBack: true),
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
            return const Center(child: Text("Etkinlik verisi bulunamadı."));
          }

          final allEvents = snapshot.data!['events'] as List<dynamic>? ?? [];

          // Map üzerinden filtreleme yapıyoruz
          final filteredEvents = allEvents.where((e) {
            final title = e['title']?.toString() ?? "";
            final description = e['description']?.toString() ?? "";
            final category = e['category']?.toString() ?? "";

            final matchesSearch = title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                description.toLowerCase().contains(_searchQuery.toLowerCase());

            final mappedFilter = _selectedFilter == "Akademik" ? "academic" :
            _selectedFilter == "Kültürel" ? "cultural" :
            _selectedFilter == "Spor" ? "sports" :
            _selectedFilter == "Sosyal" ? "social" : "Tümü";

            final matchesFilter = _selectedFilter == "Tümü" || category == mappedFilter;
            return matchesSearch && matchesFilter;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppSearchBar(
                  placeholder: "Etkinlik ara...",
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
                child: filteredEvents.isEmpty
                    ? const Center(child: Text("Aramanıza uygun etkinlik bulunamadı.", style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final e = filteredEvents[index];
                    return InfoCard(
                      title: e['title'] ?? "",
                      subtitle: e['description'] ?? "",
                      metadata: "${e['date']} • ${e['time']} | ${e['location']}",
                      badge: AppBadge(label: _getCategoryLabel(e['category'] ?? "")),
                      onTap: () => Navigator.push(
                          context,
                          // Artık modele değil, Map objesine (e) gönderiyoruz
                          MaterialPageRoute(builder: (_) => EventDetailScreen(eventData: e))
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