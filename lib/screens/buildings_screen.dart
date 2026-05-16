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
  String _selectedCampusKey = "Ataköy";
  String _selectedCategory = "All";
  late Future<Map<String, dynamic>> _databaseFuture;

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case "Academic Units":
        return Icons.school_outlined;
      case "Classrooms & Labs":
        return Icons.meeting_room_outlined;
      case "Halls & Event Spaces":
        return Icons.event_seat_outlined;
      case "Food & Beverage":
        return Icons.restaurant_outlined;
      case "Study & Library":
        return Icons.local_library_outlined;
      case "Student Services":
        return Icons.support_agent_outlined;
      case "Health & Security":
        return Icons.health_and_safety_outlined;
      default:
        return Icons.location_city_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case "Food & Beverage":
        return Colors.orange;
      case "Study & Library":
        return Colors.indigo;
      case "Health & Security":
        return Colors.redAccent;
      case "Halls & Event Spaces":
        return Colors.purple;
      case "Classrooms & Labs":
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }

  Future<void> _openCampusMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedAddress");

    try {
      final bool opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open map.")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error opening map: $e")));
    }
  }

  Map<String, String> get _selectedCampus {
    return DataService.campusDirectoryCampuses.firstWhere(
      (campus) => campus['key'] == _selectedCampusKey,
      orElse: () => DataService.campusDirectoryCampuses.first,
    );
  }

  Widget _buildCampusSelector() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: DataService.campusDirectoryCampuses.length,
        itemBuilder: (context, index) {
          final campus = DataService.campusDirectoryCampuses[index];
          final key = campus['key']!;
          return AppFilterChip(
            label: key,
            active: _selectedCampusKey == key,
            onTap: () => setState(() => _selectedCampusKey = key),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: DataService.campusUnitCategories.length,
        itemBuilder: (context, index) {
          final category = DataService.campusUnitCategories[index];
          return AppFilterChip(
            label: category,
            active: _selectedCategory == category,
            onTap: () => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildSelectedCampusCard(Color textColor, Color mutedColor) {
    final campus = _selectedCampus;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryLight.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: const Icon(Icons.map_outlined, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campus['label']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap the map icon to open this campus in Google Maps.",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: mutedColor),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: "Open in map",
              onPressed: () => _openCampusMap(campus['address']!),
              icon: const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            "$count",
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final category = DataService.campusUnitCategory(unit);
    final type = unit['typeNormalized']?.toString() ?? DataService.normalizeCampusUnitType(unit['type']?.toString());
    final floor = unit['floor']?.toString();
    final roomCode = unit['roomCode']?.toString();
    final building = unit['building']?.toString();
    final metadataParts = <String>[
      type,
      if (building != null && building.trim().isNotEmpty) building,
      if (floor != null && floor.trim().isNotEmpty) floor,
      if (roomCode != null && roomCode.trim().isNotEmpty) roomCode,
    ];

    return InfoCard(
      title: unit['name']?.toString() ?? "Unnamed unit",
      subtitle: unit['location']?.toString() ?? unit['campusDisplayName']?.toString() ?? "",
      metadata: metadataParts.join(" • "),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _categoryColor(category).withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(_categoryIcon(category), color: _categoryColor(category), size: 22),
      ),
      badge: AppBadge(label: category),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BuildingDetailScreen(buildingData: unit)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Scaffold(
      appBar: CustomAppBar(title: "Campus Guide", showBack: widget.showBackButton),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _databaseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!['buildings'] == null) {
            return const Center(child: Text("Campus unit data not found."));
          }

          final allUnits = (snapshot.data!['buildings'] as List<dynamic>? ?? [])
              .whereType<Map<dynamic, dynamic>>()
              .map((unit) => DataService.normalizeCampusUnitRecord(unit))
              .where((unit) => DataService.isCampusUnitVisible(unit))
              .toList();

          final sq = _normalize(_searchQuery);
          final filteredUnits = allUnits.where((unit) {
            final campusMatches = unit['campusKey'] == _selectedCampusKey;
            final category = DataService.campusUnitCategory(unit);
            final categoryMatches = _selectedCategory == "All" || category == _selectedCategory;

            final searchable = [
              unit['name'],
              unit['abbr'],
              unit['location'],
              unit['building'],
              unit['roomCode'],
              unit['type'],
              unit['typeNormalized'],
              unit['category'],
            ].whereType<Object>().map((value) => value.toString()).join(' ');
            final searchMatches = sq.isEmpty || _normalize(searchable).contains(sq);

            return campusMatches && categoryMatches && searchMatches;
          }).toList()
            ..sort((a, b) {
              final featuredCompare = (b['isFeatured'] == true ? 1 : 0).compareTo(a['isFeatured'] == true ? 1 : 0);
              if (featuredCompare != 0) return featuredCompare;
              final orderCompare = (a['sortOrder'] as int).compareTo(b['sortOrder'] as int);
              if (orderCompare != 0) return orderCompare;
              return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
            });

          final featuredUnits = filteredUnits.where((unit) => unit['isFeatured'] == true).take(5).toList();
          final regularUnits = filteredUnits.where((unit) => unit['isFeatured'] != true).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppSearchBar(
                    placeholder: "Search unit, faculty, library, cafeteria, or service...",
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildCampusSelector()),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(child: _buildCategorySelector()),
              SliverToBoxAdapter(child: _buildSelectedCampusCard(textColor, mutedColor)),

              if (filteredUnits.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        "No campus unit found matching your filters.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                      ),
                    ),
                  ),
                ),

              if (featuredUnits.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildSectionTitle("Featured / Useful", featuredUnits.length)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildUnitCard(featuredUnits[index]),
                      childCount: featuredUnits.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 6)),
              ],

              if (regularUnits.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildSectionTitle("All Campus Units", regularUnits.length)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildUnitCard(regularUnits[index]),
                      childCount: regularUnits.length,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}
