import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/info_card.dart';
import '../data/data_service.dart'; // MOCK DATA YERİNE JSON SERVİSİ
import 'classroom_detail_screen.dart';

class BuildingDetailScreen extends StatelessWidget {
  // Artık Building nesnesi yerine Map alıyoruz
  final Map<String, dynamic> buildingData;

  const BuildingDetailScreen({Key? key, required this.buildingData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: buildingData['name'] ?? 'Bina Detayı', showBack: true),
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
                    AppBadge(label: buildingData['abbr'] ?? '', backgroundColor: AppTheme.primaryColor, textColor: Colors.white),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(Icons.layers, "${buildingData['floors']} Kat"),
                        _buildStat(Icons.meeting_room, "${buildingData['rooms']} Oda"),
                        _buildStat(Icons.location_on, buildingData['location'] ?? ''),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bu binaya ait derslikleri bulmak için JSON verisini çekiyoruz
            FutureBuilder<Map<String, dynamic>>(
              future: DataService.loadDatabase(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) return const SizedBox();

                final allClassrooms = snapshot.data!['classrooms'] as List<dynamic>? ?? [];

                // Seçili binanın adına göre derslikleri filtrele
                final relatedClassrooms = allClassrooms.where((c) => c['building'] == buildingData['name']).toList();

                if (relatedClassrooms.isEmpty) return const SizedBox(); // Derslik yoksa boş dön

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: "Bu Binada Derslikler"),
                    ...relatedClassrooms.map((c) => InfoCard(
                      title: c['name'] ?? '',
                      subtitle: "${c['type']} • Kat ${c['floor']}",
                      metadata: "Kapasite: ${c['capacity']} Kişi",
                      onTap: () => Navigator.push(
                          context,
                          // DİKKAT: ClassroomDetailScreen sayfası da güncellenmeli!
                          MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroomData: c))
                      ),
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
        Icon(icon, color: AppTheme.textMuted),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }
}