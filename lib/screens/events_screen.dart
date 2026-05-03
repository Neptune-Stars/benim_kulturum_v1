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
  const EventsScreen({Key? key, this.showOnlyJoined = false}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "All";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _filters = ["All", "Academic", "Cultural", "Sports", "Social"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  String _getCategoryLabel(String cat) {
    switch (cat.toLowerCase()) {
      case "academic": return "Academic";
      case "cultural": return "Cultural";
      case "sports": return "Sports";
      case "social": return "Social";
      default: return "General";
    }
  }

  @override
  Widget build(BuildContext context) {
    final joinedProvider = context.watch<JoinedEventsProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.showOnlyJoined ? "My Events" : "Events",
        showBack: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData) return const Center(child: Text("Event data not found."));

            final allEvents = snapshot.data!['events'] as List<dynamic>? ?? [];

            final filteredEvents = allEvents.where((e) {
              final title = e['title']?.toString().toLowerCase() ?? "";
              final category = e['category']?.toString() ?? "";
              final matchesSearch = title.contains(_searchQuery.toLowerCase());

              final mappedFilter = _selectedFilter.toLowerCase();
              final matchesFilter = _selectedFilter == "All" || category == mappedFilter;
              final matchesJoined = !widget.showOnlyJoined || joinedProvider.isJoined(e['id']);

              return matchesSearch && matchesFilter && matchesJoined;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppSearchBar(placeholder: "Search events...", onChanged: (val) => setState(() => _searchQuery = val)),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) => AppFilterChip(
                        label: _filters[index],
                        active: _selectedFilter == _filters[index],
                        onTap: () => setState(() => _selectedFilter = _filters[index])
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredEvents.isEmpty
                      ? Center(child: Text(widget.showOnlyJoined ? "You haven't joined any events yet." : "No events found."))
                      : ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final e = filteredEvents[index];
                      final isJoined = joinedProvider.isJoined(e['id']);
                      return InfoCard(
                        title: e['title'] ?? "",
                        subtitle: e['description'] ?? "",
                        metadata: "${e['date']} • ${e['time']} | ${e['location']}",
                        badge: AppBadge(
                          label: isJoined ? "Joined" : _getCategoryLabel(e['category'] ?? ""),
                          backgroundColor: isJoined ? AppTheme.successColor.withOpacity(0.12) : null,
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventData: e))),
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