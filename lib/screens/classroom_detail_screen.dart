import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_header.dart';
import '../providers/favorites_provider.dart';

class ClassroomDetailScreen extends StatelessWidget {
  final Map<String, dynamic> classroomData;

  const ClassroomDetailScreen({Key? key, required this.classroomData}) : super(key: key);


  String _floorLabel(dynamic floorLabel, dynamic floor) {
    final raw = (floorLabel?.toString().trim().isNotEmpty ?? false)
        ? floorLabel.toString().trim()
        : (floor?.toString().trim() ?? '');

    if (raw.isEmpty) return 'No Floor Info';

    final normalized = raw
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (compact == 'b1b2' ||
        compact == 'b2b1' ||
        normalized.contains('b1 and b2') ||
        normalized.contains('b1 / b2') ||
        normalized.contains('b1-b2')) {
      return 'B1-B2 Floors';
    }
    if (compact == 'b2' || compact == 'b2floor') return 'B2 Floor';
    if (compact == 'b1' || compact == 'b1floor') return 'B1 Floor';
    if (normalized == 'basement' || normalized == 'basement floor') return 'Basement Floor';
    if (normalized == 'ground' || normalized == 'ground floor') return 'Ground Floor';
    if (normalized == 'entrance' || normalized == 'entrance floor') return 'Entrance Floor';
    if (normalized == 'mezzanine' || normalized == 'mezzanine floor') return 'Mezzanine Floor';
    if (raw.contains('Floor')) return raw;

    final number = int.tryParse(raw);
    if (number == -2) return 'B2 Floor';
    if (number == -1) return 'Basement Floor';
    if (number == 0) return 'Ground Floor';
    if (number != null && number > 0) return '${number}th Floor';

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite("class_${classroomData['id']}");
    final floorText = _floorLabel(classroomData['floorLabel'], classroomData['floor']);

    return Scaffold(
      appBar: CustomAppBar(
        title: classroomData['name'] ?? 'Classroom',
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? AppTheme.warningColor : AppTheme.textPrimary,
            ),
            onPressed: () => context.read<FavoritesProvider>().toggleFavorite("class_${classroomData['id']}"),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.meeting_room, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  classroomData['building']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${classroomData['type']} • $floorText",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.textMuted, height: 1.25),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _buildClassroomStat(
                              icon: Icons.people_outline,
                              label: "${classroomData['capacity']} People",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildClassroomStat(
                              icon: Icons.stairs_outlined,
                              label: floorText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: "Available Hours (Example)"),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Text(
                  "Schedule data not loaded yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassroomStat({required IconData icon, required String label}) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textMuted),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25),
        ),
      ],
    );
  }
}
