import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_header.dart';
import '../providers/favorites_provider.dart';

class ClassroomDetailScreen extends StatelessWidget {
  final Map<String, dynamic> classroomData;

  const ClassroomDetailScreen({super.key, required this.classroomData});

  String _floorLabel(dynamic floorLabel, dynamic floor) {
    final raw = (floorLabel?.toString().trim().isNotEmpty ?? false)
        ? floorLabel.toString().trim()
        : (floor?.toString().trim() ?? '');

    if (raw.isEmpty) return 'Ground Floor';

    final normalized = raw.toLowerCase().replaceAll('ı', 'i').trim();
    final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');

    // B1-B2 (covers both basement floors)
    if (compact == 'b1b2' ||
        compact == 'b2b1' ||
        normalized.contains('b1 and b2') ||
        normalized.contains('b1 / b2') ||
        normalized.contains('b1-b2')) {
      return 'B1-B2 Floors';
    }

    // B2 (basement 2)
    if (compact == 'b2' || compact == 'b2floor') return 'B2 Floor';

    // B1 (basement 1)
    if (compact == 'b1' || compact == 'b1floor') return 'B1 Floor';

    if (normalized.contains('basement') || normalized == '-1') return 'Basement Floor';
    if (normalized.contains('ground') || normalized == '0') return 'Ground Floor';
    if (normalized.contains('entrance')) return 'Entrance Floor';
    if (normalized.contains('mezzanine')) return 'Mezzanine Floor';
    if (raw.contains('Floor')) return raw;

    final number = int.tryParse(raw);
    if (number != null) {
      if (number == -2) return 'B2 Floor';
      if (number == -1) return 'B1 Floor';
      if (number == 0) return 'Ground Floor';
      return '$number. Floor';
    }

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite("class_${classroomData['id']}");

    final String name = classroomData['name'] ?? 'Classroom';
    final String type = classroomData['type'] ?? 'Classroom';
    final String campus = classroomData['campus'] ?? 'Unknown Campus';
    final String location = classroomData['location'] ?? classroomData['building'] ?? 'General Building';

    final String capacity = (classroomData['capacity'] ?? '40').toString();
    final String floorText = _floorLabel(classroomData['floorLabel'], classroomData['floor']);

    final cardColor = Theme.of(context).cardColor;
    final dividerColor = Theme.of(context).dividerColor;

    return Scaffold(
      appBar: CustomAppBar(
        title: name,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.meeting_room, color: AppTheme.primaryColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                type,
                                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.people_outline, "$capacity Seats"),
                        _buildStatItem(Icons.layers_outlined, floorText),
                        _buildStatItem(Icons.location_on_outlined, campus.split(' ').first),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: "Location Details"),

            _buildLocationDetailTile(Icons.business, "Campus", campus),
            _buildLocationDetailTile(Icons.apartment, "Building / Block", location),

            const SizedBox(height: 32),
            const SectionHeader(title: "Today's Schedule"),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor),
              ),
              child: Column(
                children: [
                  _buildScheduleRow("09:00 - 12:00", "Algorithm & Programming", "Ongoing", isActive: true),
                  const Divider(height: 1),
                  _buildScheduleRow("13:00 - 15:00", "Data Structures", "Upcoming"),
                  const Divider(height: 1),
                  _buildScheduleRow("15:30 - 17:30", "Project Management", "Upcoming"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: "$name - $campus, $location"));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Location copied to clipboard!")),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text("Copy Full Address"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLocationDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textMuted))),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String time, String subject, String status, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(time, style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppTheme.primaryColor : null,
          )),
          const SizedBox(width: 16),
          Expanded(
            child: Text(subject, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.successColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? AppTheme.successColor : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}