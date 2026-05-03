import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart';
import 'building_detail_screen.dart';

class BuildingsScreen extends StatefulWidget {
  final bool showBackButton;
  const BuildingsScreen({Key? key, this.showBackButton = true}) : super(key: key);
  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Faculties", "Admin Units", "Social Areas", "Dining", "Study Areas"];

  final List<Map<String, String>> _campuses = [
    {"title": "Atakoy", "address": "IKU Atakoy Campus, Istanbul"},
    {"title": "Sirinevler", "address": "IKU Sirinevler Campus, Istanbul"},
    {"title": "Incirli", "address": "IKU Incirli Campus, Istanbul"},
    {"title": "Basin Ekspres", "address": "IKU Basin Ekspres Campus, Istanbul"},
  ];

  bool _matchesFilter(String selectedFilter, String rawType) {
    if (selectedFilter == "All") return true;
    if (selectedFilter == "Faculties" && rawType == "faculty") return true;
    if (selectedFilter == "Admin Units" && rawType == "admin") return true;
    if (selectedFilter == "Social Areas" && rawType == "social") return true;
    if (selectedFilter == "Dining" && rawType == "food") return true;
    if (selectedFilter == "Study Areas" && rawType == "study") return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Campus Guide"),
      body: FutureBuilder<Map<String, dynamic>>(
        future: DataService.loadDatabase(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final filtered = (snapshot.data!['buildings'] as List).where((b) {
            return b['name'].toLowerCase().contains(_searchQuery.toLowerCase()) && _matchesFilter(_selectedFilter, b['type']);
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppSearchBar(placeholder: "Search units or faculties...", onChanged: (v) => setState(() => _searchQuery = v)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, i) => AppFilterChip(label: _filters[i], active: _selectedFilter == _filters[i], onTap: () => setState(() => _selectedFilter = _filters[i])),
                  ),
                ),
              ),
              // Map section and list logic remains the same, just labels are translated...
            ],
          );
        },
      ),
    );
  }
}