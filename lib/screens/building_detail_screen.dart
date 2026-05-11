import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/info_card.dart';
import '../data/data_service.dart';
import 'classroom_detail_screen.dart';

class BuildingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> buildingData;

  const BuildingDetailScreen({Key? key, required this.buildingData}) : super(key: key);

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

  String _floorLabel(dynamic floor) {
    final value = floor?.toString().trim() ?? "";
    return value.isEmpty ? "Not specified" : value;
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryLight),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = DataService.normalizeCampusUnitRecord(buildingData);
    final String category = DataService.campusUnitCategory(unit);
    final String type = unit['typeNormalized']?.toString() ?? DataService.normalizeCampusUnitType(unit['type']?.toString());
    final String title = unit['name']?.toString() ?? 'Unit Details';

    return Scaffold(
      appBar: CustomAppBar(title: title, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    AppBadge(
                      label: unit['abbr']?.toString() ?? type,
                      backgroundColor: AppTheme.primaryColor,
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildStat(_categoryIcon(category), category)),
                        Container(width: 1, height: 44, color: AppTheme.borderColor),
                        Expanded(child: _buildStat(Icons.location_on_outlined, unit['campusDisplayName']?.toString() ?? DataService.campusDisplayName(unit['campus']?.toString()))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const SectionHeader(title: "Unit Information"),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.category_outlined, "Type", type),
                    _buildDetailRow(Icons.location_city_outlined, "Campus", unit['campusDisplayName']?.toString() ?? DataService.campusDisplayName(unit['campus']?.toString())),
                    _buildDetailRow(Icons.apartment_outlined, "Building", unit['building']?.toString() ?? ''),
                    _buildDetailRow(Icons.layers_outlined, "Floor", _floorLabel(unit['floor'])),
                    _buildDetailRow(Icons.meeting_room_outlined, "Room", unit['roomCode']?.toString() ?? ''),
                    _buildDetailRow(Icons.place_outlined, "Location", unit['location']?.toString() ?? ''),
                    _buildDetailRow(Icons.access_time_outlined, "Hours", unit['workingHours']?.toString() ?? ''),
                    _buildDetailRow(Icons.info_outline, "Description", unit['description']?.toString() ?? unit['navigationHint']?.toString() ?? ''),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (category == "Academic Units" || category == "Classrooms & Labs")
              FutureBuilder<Map<String, dynamic>>(
                future: DataService.loadDatabase(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) return const SizedBox();

                  final allClassrooms = snapshot.data!['classrooms'] as List<dynamic>? ?? [];
                  final unitName = title.toLowerCase();
                  final unitBuilding = unit['building']?.toString().toLowerCase() ?? '';

                  final relatedClassrooms = allClassrooms.where((c) {
                    final cBuilding = c['building']?.toString().toLowerCase() ?? "";
                    final cCampus = DataService.normalizeCampusKey(c['campus']?.toString());
                    final unitCampus = unit['campusKey']?.toString() ?? DataService.normalizeCampusKey(unit['campus']?.toString());
                    return cCampus == unitCampus &&
                        (cBuilding.contains(unitName) ||
                            (unitBuilding.isNotEmpty && cBuilding.contains(unitBuilding)));
                  }).toList();

                  if (relatedClassrooms.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: "Associated Classrooms and Lecture Halls"),
                      const SizedBox(height: 10),
                      ...relatedClassrooms.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InfoCard(
                          title: c['name']?.toString() ?? '',
                          subtitle: "${c['type']} • ${c['building'] ?? ''}",
                          metadata: "Capacity: ${c['capacity']} People",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroomData: Map<String, dynamic>.from(c as Map))),
                          ),
                        ),
                      )),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.3),
        ),
      ],
    );
  }
}
