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

  String _getTypeLabel(String rawType) {
    switch (rawType.toLowerCase()) {
      case "faculty": return "Academic Unit";
      case "admin": return "Admin Unit";
      case "social": return "Social Area";
      case "food": return "Dining";
      case "study": return "Study Area";
      default: return "Campus Area";
    }
  }

  IconData _getTypeIcon(String rawType) {
    switch (rawType.toLowerCase()) {
      case "faculty": return Icons.school;
      case "admin": return Icons.business_center;
      case "social": return Icons.park;
      case "food": return Icons.restaurant;
      case "study": return Icons.local_library;
      default: return Icons.location_city;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String type = buildingData['type']?.toString() ?? "unknown";

    return Scaffold(
      appBar: CustomAppBar(title: buildingData['name'] ?? 'Unit Detail', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    AppBadge(label: buildingData['abbr'] ?? '', backgroundColor: AppTheme.primaryColor),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildStat(_getTypeIcon(type), _getTypeLabel(type))),
                        Container(width: 1, height: 40, color: AppTheme.borderColor),
                        Expanded(child: _buildStat(Icons.location_on, buildingData['location'] ?? 'Unknown')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (type == "faculty")
              FutureBuilder<Map<String, dynamic>>(
                future: DataService.loadDatabase(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                  final classrooms = (snapshot.data?['classrooms'] as List?)?.where((c) =>
                      c['building'].toString().contains(buildingData['name'])).toList() ?? [];

                  if (classrooms.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No classrooms found for this unit."));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: "Related Classrooms & Labs"),
                      ...classrooms.map((c) => InfoCard(
                        title: c['name'] ?? '',
                        subtitle: "${c['type']} • Floor ${c['floor']}",
                        metadata: "Capacity: ${c['capacity']} People",
                      )).toList(),
                    ],
                  );
                },
              )
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
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}