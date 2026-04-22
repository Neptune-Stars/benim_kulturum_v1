import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart';
import '../providers/joined_events_provider.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  final bool showOnlyJoined;

  const EventsScreen({
    Key? key,
    this.showOnlyJoined = false,
  }) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _filters = [
    "Tümü",
    "Akademik",
    "Kültürel",
    "Spor",
    "Sosyal",
  ];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case "academic": return "Akademik";
      case "cultural": return "Kültürel";
      case "sports": return "Spor";
      case "social": return "Sosyal";
      default: return "Genel";
    }
  }

  @override
  Widget build(BuildContext context) {
    final joinedProvider = context.watch<JoinedEventsProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.showOnlyJoined ? "Etkinliklerim" : "Etkinlikler",
        showBack: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!['events'] == null) {
              return const Center(child: Text("Etkinlik verisi bulunamadı."));
            }

            final allEvents = snapshot.data!['events'] as List<dynamic>? ?? [];

            final filteredEvents = allEvents.where((e) {
              final title = e['title']?.toString() ?? "";
              final description = e['description']?.toString() ?? "";
              final category = e['category']?.toString() ?? "";
              final eventId = e['id'];

              final matchesSearch = title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  description.toLowerCase().contains(_searchQuery.toLowerCase());

              final mappedFilter = _selectedFilter == "Akademik" ? "academic"
                  : _selectedFilter == "Kültürel" ? "cultural"
                  : _selectedFilter == "Spor" ? "sports"
                  : _selectedFilter == "Sosyal" ? "social" : "Tümü";

              final matchesFilter = _selectedFilter == "Tümü" || category == mappedFilter;

              final matchesJoined = !widget.showOnlyJoined || joinedProvider.isJoined(eventId);

              return matchesSearch && matchesFilter && matchesJoined;
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
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        widget.showOnlyJoined ? "Henüz katıldığın bir etkinlik yok." : "Etkinlik bulunamadı.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                      ),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final e = filteredEvents[index];
                      final isJoined = joinedProvider.isJoined(e['id']);

                      return InfoCard(
                        title: e['title']?.toString() ?? "",
                        subtitle: e['description']?.toString() ?? "",
                        metadata: "${e['date']} • ${e['time']} | ${e['location']}",
                        badge: AppBadge(
                          label: isJoined ? "Katıldın" : _getCategoryLabel(e['category']?.toString() ?? ""),
                          backgroundColor: isJoined ? AppTheme.successColor.withOpacity(0.12) : null,
                          textColor: isJoined ? AppTheme.successColor : null,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EventDetailScreen(eventData: e)),
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