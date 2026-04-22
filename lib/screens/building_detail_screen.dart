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
      case "faculty": return "Akademik Birim";
      case "admin": return "İdari Birim";
      case "social": return "Sosyal Alan";
      case "food": return "Yeme-İçme";
      case "study": return "Çalışma Alanı";
      default: return "Kampüs Alanı";
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
      appBar: CustomAppBar(title: buildingData['name'] ?? 'Birim Detayı', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // YENİ TİP İSTATİSTİK KARTI (Gereksiz kat/oda sayıları kaldırıldı)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    AppBadge(
                        label: buildingData['abbr'] ?? '',
                        backgroundColor: AppTheme.primaryColor,
                        textColor: Colors.white
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildStat(_getTypeIcon(type), _getTypeLabel(type))),
                        Container(width: 1, height: 40, color: AppTheme.borderColor),
                        Expanded(child: _buildStat(Icons.location_on, buildingData['location'] ?? 'Bilinmiyor')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // EĞER BU BİR AKADEMİK BİRİMSE (Fakülte), İÇİNDEKİ DERSLİKLERİ GÖSTER
            if (type == "faculty")
              FutureBuilder<Map<String, dynamic>>(
                future: DataService.loadDatabase(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) return const SizedBox();

                  final allClassrooms = snapshot.data!['classrooms'] as List<dynamic>? ?? [];

                  // Derslikleri artık binaya göre değil, bağlı olduğu "birime" göre filtreliyoruz
                  final relatedClassrooms = allClassrooms.where((c) {
                    String cBuilding = c['building']?.toString() ?? "";
                    // Dersliğin bağlı olduğu birim, açtığımız bu birimin adıyla eşleşiyorsa
                    return cBuilding.contains(buildingData['name']);
                  }).toList();

                  if (relatedClassrooms.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text("Bu birime tanımlanmış derslik bulunamadı.", style: TextStyle(color: AppTheme.textMuted))),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: "Bağlı Derslikler ve Amfiler"),
                      const SizedBox(height: 10),
                      ...relatedClassrooms.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InfoCard(
                          title: c['name']?.toString() ?? '',
                          subtitle: "${c['type']} • Kat ${c['floor']}",
                          metadata: "Kapasite: ${c['capacity']} Kişi",
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroomData: c))
                          ),
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
        Icon(icon, color: AppTheme.primaryLight, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.3),
        ),
      ],
    );
  }
}