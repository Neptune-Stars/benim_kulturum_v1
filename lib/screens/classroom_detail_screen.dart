import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models/classroom.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_header.dart';
import '../providers/favorites_provider.dart';

class ClassroomDetailScreen extends StatelessWidget {
  final Classroom classroom;

  const ClassroomDetailScreen({Key? key, required this.classroom}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite("class_${classroom.id}");

    return Scaffold(
      appBar: CustomAppBar(
        title: classroom.name,
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? AppTheme.warningColor : AppTheme.textPrimary),
            onPressed: () => context.read<FavoritesProvider>().toggleFavorite("class_${classroom.id}"),
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
                              Text(classroom.building, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("${classroom.type} • Kat ${classroom.floor}", style: const TextStyle(color: AppTheme.textMuted)),
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
                            Text("${classroom.capacity} Kişi", style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.stairs_outlined, color: AppTheme.textMuted),
                            const SizedBox(height: 4),
                            Text("Kat ${classroom.floor}", style: const TextStyle(fontWeight: FontWeight.w600)),
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