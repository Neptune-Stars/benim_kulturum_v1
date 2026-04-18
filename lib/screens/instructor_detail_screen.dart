import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models/instructor.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import '../widgets/section_header.dart';
import '../providers/favorites_provider.dart';

class InstructorDetailScreen extends StatelessWidget {
  final Instructor instructor;

  const InstructorDetailScreen({Key? key, required this.instructor}) : super(key: key);

  String getInitials(String name) {
    List<String> names = name.replaceAll(RegExp(r'(Prof\. Dr\.|Doç\. Dr\.|Dr\. Öğr\. Üyesi)\s*'), '').split(" ");
    if (names.length >= 2) {
      return "${names[0][0]}${names[names.length-1][0]}".toUpperCase();
    }
    return names.isNotEmpty ? names[0][0].toUpperCase() : "?";
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite("inst_${instructor.id}");

    return Scaffold(
      appBar: CustomAppBar(
        title: instructor.name,
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? AppTheme.warningColor : AppTheme.textPrimary),
            onPressed: () => context.read<FavoritesProvider>().toggleFavorite("inst_${instructor.id}"),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                    child: Text(
                      getInitials(instructor.name),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppBadge(label: instructor.title, backgroundColor: AppTheme.primaryColor, textColor: Colors.white),
                  const SizedBox(height: 8),
                  Text(instructor.department, style: const TextStyle(fontSize: 16, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text("Ofis: ${instructor.office}", style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.email),
                label: const Text("E-posta ile İletişim", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
            const SectionHeader(title: "Ofis Saatleri"),
            Card(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildOfficeHourRow("Pazartesi", "10:00 - 12:00"),
                  const Divider(height: 1),
                  _buildOfficeHourRow("Çarşamba", "14:00 - 16:00"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeHourRow(String day, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          Text(time, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}