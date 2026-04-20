import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// classroom.dart model importunu kaldırdık çünkü artık JSON Map kullanıyoruz
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_header.dart';
import '../providers/favorites_provider.dart';

class ClassroomDetailScreen extends StatelessWidget {
  // Classroom nesnesi yerine JSON'dan gelen Map'i alıyoruz
  final Map<String, dynamic> classroomData;

  const ClassroomDetailScreen({Key? key, required this.classroomData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    // id değerini Map'ten okuyoruz
    final isFav = favProvider.isFavorite("class_${classroomData['id']}");

    return Scaffold(
      appBar: CustomAppBar(
        title: classroomData['name'] ?? 'Derslik', // name değerini Map'ten okuyoruz
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? AppTheme.warningColor : AppTheme.textPrimary),
            onPressed: () => context.read<FavoritesProvider>().toggleFavorite("class_${classroomData['id']}"),
          )
        ],
      ),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.primaryLight.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.meeting_room, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(classroomData['building'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("${classroomData['type']} • Kat ${classroomData['floor']}", style: const TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.people_outline, color: AppTheme.textMuted),
                            const SizedBox(height: 4),
                            Text("${classroomData['capacity']} Kişi", style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.stairs_outlined, color: AppTheme.textMuted),
                            const SizedBox(height: 4),
                            Text("Kat ${classroomData['floor']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: "Uygun Saatler (Örnek)"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Center(
                child: Text(
                  "Program verisi henüz yüklenmedi.",
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}