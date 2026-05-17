import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import '../widgets/section_header.dart';
import '../providers/favorites_provider.dart';

class InstructorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> instructorData;

  const InstructorDetailScreen({Key? key, required this.instructorData}) : super(key: key);

  String getInitials(String name) {
    List<String> names = name.replaceAll(RegExp(r'(Prof\. Dr\.|Doç\. Dr\.|Dr\. Öğr\. Üyesi|Assoc\. Prof\. Dr\.|Asst\. Prof\. Dr\.)\s*'), '').split(" ");
    if (names.length >= 2) {
      return "${names[0][0]}${names[names.length - 1][0]}".toUpperCase();
    }
    return names.isNotEmpty ? names[0][0].toUpperCase() : "?";
  }

  String _cleanOfficeHourTime(String value) {
    final withoutPipeOffice = value.split('|').first.trim();
    final cleaned = withoutPipeOffice
        .replaceAll(RegExp(r'\s*Office\s*:.*$', caseSensitive: false), '')
        .trim();

    return cleaned.isNotEmpty ? cleaned : "-";
  }

  String _resolveInstructorFavoriteId() {
    final rawId = instructorData['id'] ??
        instructorData['firestoreDocId'] ??
        instructorData['docId'] ??
        instructorData['email'] ??
        instructorData['name'];

    return rawId?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final instructorFavoriteId = _resolveInstructorFavoriteId();
    final isFav = instructorFavoriteId.isNotEmpty
        ? favProvider.isFavorite("inst_$instructorFavoriteId")
        : false;

    final String name = instructorData['name'] ?? 'Unknown';
    final String title = instructorData['title'] ?? '';
    final String department = instructorData['department'] ?? '';
    final String office = instructorData['office'] ?? 'Unknown';

    final List<dynamic> displayHours =
    (instructorData['officeHours'] is List &&
        (instructorData['officeHours'] as List).isNotEmpty)
        ? instructorData['officeHours']
        : <dynamic>[];

    final String email = (instructorData['email'] != null && instructorData['email'].toString().isNotEmpty)
        ? instructorData['email']
        : 'contact@uni.edu.tr';

    final String? imageUrl = instructorData['imageUrl'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final dividerColor = Theme.of(context).dividerColor;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: CustomAppBar(
        title: name,
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? AppTheme.warningColor : AppTheme.textPrimary),
            onPressed: instructorFavoriteId.isEmpty
                ? null
                : () => context
                .read<FavoritesProvider>()
                .toggleFavorite("inst_$instructorFavoriteId"),
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
                    backgroundColor: AppTheme.primaryLight.withOpacity(0.18),
                    backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                        ? AssetImage(imageUrl)
                        : null,
                    child: imageUrl == null || imageUrl.isEmpty
                        ? Text(
                      getInitials(name),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppBadge(label: title, backgroundColor: AppTheme.primaryColor, textColor: Colors.white),
                  const SizedBox(height: 8),
                  Text(department, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: mutedColor)),
                  const SizedBox(height: 4),
                  Text("Main Office: $office", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Email Copy Area
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: email)).then((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Email address copied!"), duration: Duration(seconds: 2)),
                      );
                    }
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dividerColor)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(email, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                      ),
                      Icon(Icons.copy, size: 18, color: mutedColor),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const SectionHeader(title: "Office Hours"),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: dividerColor),
              ),
              child: displayHours.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Office hour information has not been added yet.",
                  style: TextStyle(color: mutedColor, height: 1.4),
                ),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayHours.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = displayHours[index];

                  String day = "Meeting";
                  String time = "-";
                  if (item is Map) {
                    day = item['day']?.toString() ?? "Unknown";
                    final start = item['startTime']?.toString() ?? '';
                    final end = item['endTime']?.toString() ?? '';
                    time = _cleanOfficeHourTime("$start - $end");
                  } else {
                    final String hourInfo = item.toString();
                    if (hourInfo.contains(':')) {
                      var parts = hourInfo.split(':');
                      day = parts[0].trim();
                      time = _cleanOfficeHourTime(parts.sublist(1).join(':').trim());
                    } else {
                      time = _cleanOfficeHourTime(hourInfo);
                    }
                  }

                  return _buildOfficeHourRow(context, day, time);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeHourRow(BuildContext context, String day, String time) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                time,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}