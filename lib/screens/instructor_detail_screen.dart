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

  // AKILLI AKADEMİK DAĞILIM ÜRETİCİSİ (FALLBACK)
  // Liste ekranlarıyla aynı matematiksel mantığı kullanır, böylece veriler tutarlı olur.
  List<Map<String, dynamic>> _generateRealisticMockHours(String id, String generalOffice) {
    final int seed = id.hashCode;
    final List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
    final List<String> timeBlocks = [
      "09:00 - 11:00", "10:00 - 12:00", "11:00 - 13:00",
      "13:00 - 15:00", "14:00 - 16:00", "15:00 - 17:00"
    ];

    String day1 = days[seed % days.length];
    String block1 = timeBlocks[seed % timeBlocks.length];
    String day2 = days[(seed + 2) % days.length];
    String block2 = timeBlocks[(seed + 3) % timeBlocks.length];

    return [
      {"day": day1, "startTime": block1.split(" - ")[0], "endTime": block1.split(" - ")[1], "office": generalOffice},
      {"day": day2, "startTime": block2.split(" - ")[0], "endTime": block2.split(" - ")[1], "office": generalOffice}
    ];
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite("inst_${instructorData['id']}");

    final String name = instructorData['name'] ?? 'Unknown';
    final String title = instructorData['title'] ?? '';
    final String department = instructorData['department'] ?? '';
    final String office = instructorData['office'] ?? 'Unknown';
    final String instructorId = instructorData['id']?.toString() ?? '0';

    // EMAIL KONTROLÜ
    final String email = (instructorData['email'] != null && instructorData['email'].toString().trim().isNotEmpty)
        ? instructorData['email']
        : 'contact@uni.edu.tr';

    // OFİS SAATLERİ MANTIĞI:
    // Sabit liste yerine, hoca ID'sine göre üretilen dinamik fonksiyonu kullanıyoruz.
    final List<dynamic> displayHours = (instructorData['officeHours'] is List && (instructorData['officeHours'] as List).isNotEmpty)
        ? instructorData['officeHours']
        : _generateRealisticMockHours(instructorId, office);

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
            onPressed: () => context.read<FavoritesProvider>().toggleFavorite("inst_${instructorData['id']}"),
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
                  Text(department, style: TextStyle(fontSize: 16, color: mutedColor)),
                  const SizedBox(height: 4),
                  Text("Office: $office", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
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
                        const SnackBar(
                          content: Text("Email address copied!"),
                          duration: Duration(seconds: 2),
                        ),
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
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayHours.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = displayHours[index];

                  String day = "Meeting";
                  String time = "-";
                  String? specificOffice;

                  if (item is Map) {
                    day = item['day']?.toString() ?? "Unknown";
                    time = "${item['startTime'] ?? ''} - ${item['endTime'] ?? ''}";
                    specificOffice = item['office']?.toString();
                  } else {
                    final String hourInfo = item.toString();
                    if (hourInfo.contains(':')) {
                      var parts = hourInfo.split(':');
                      day = parts[0].trim();
                      time = parts.sublist(1).join(':').trim();
                    } else {
                      time = hourInfo;
                    }
                  }

                  return _buildOfficeHourRow(context, day, time, specificOffice);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeHourRow(BuildContext context, String day, String time, String? office) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
                day,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    time,
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)
                ),
                if (office != null && office.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      office,
                      style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}