import 'package:flutter/material.dart';
import '../models/models/building.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/info_card.dart';
import '../data/mock_data.dart';
import 'classroom_detail_screen.dart';

class BuildingDetailScreen extends StatelessWidget {
  final Building building;

  const BuildingDetailScreen({Key? key, required this.building}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final relatedClassrooms = MockData.classrooms.where((c) => c.building == building.name).toList();

    return Scaffold(
      appBar: CustomAppBar(title: building.name, showBack: true),
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
                    AppBadge(label: building.abbr, backgroundColor: AppTheme.primaryColor, textColor: Colors.white),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(Icons.layers, "${building.floors} Kat"),
                        _buildStat(Icons.meeting_room, "${building.rooms} Oda"),
                        _buildStat(Icons.location_on, building.location),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (relatedClassrooms.isNotEmpty) ...[
              const SectionHeader(title: "Bu Binada Derslikler"),
              ...relatedClassrooms.map((c) => InfoCard(
                title: c.name,
                subtitle: "${c.type} • Kat ${c.floor}",
                metadata: "Kapasite: ${c.capacity} Kişi",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroom: c))),
              )),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textMuted),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }
}