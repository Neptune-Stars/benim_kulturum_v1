import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/mock_data.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";

  final List<String> _filters = ["Tümü", "Akademik", "Kültürel", "Spor", "Sosyal"];

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
    final filteredEvents = MockData.events.where((e) {
      final matchesSearch = e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final mappedFilter = _selectedFilter == "Akademik" ? "academic" :
      _selectedFilter == "Kültürel" ? "cultural" :
      _selectedFilter == "Spor" ? "sports" :
      _selectedFilter == "Sosyal" ? "social" : "Tümü";

      final matchesFilter = _selectedFilter == "Tümü" || e.category == mappedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: "Etkinlikler", showBack: true),
      body: Column(
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final e = filteredEvents[index];
                return InfoCard(
                  title: e.title,
                  subtitle: e.description,
                  metadata: "${e.date} • ${e.time} | ${e.location}",
                  badge: AppBadge(label: _getCategoryLabel(e.category)),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EventDetailScreen(event: e))
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