import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Panoya (Clipboard) kopyalamak için eklendi
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
    List<String> names = name.replaceAll(RegExp(r'(Prof\. Dr\.|Doç\. Dr\.|Dr\. Öğr\. Üyesi)\s*'), '').split(" ");
    if (names.length >= 2) {
      return "${names[0][0]}${names[names.length - 1][0]}".toUpperCase();
    }
    return names.isNotEmpty ? names[0][0].toUpperCase() : "?";
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite("inst_${instructorData['id']}");

    // JSON'dan güvenli okuma
    final String name = instructorData['name'] ?? 'İsimsiz';
    final String title = instructorData['title'] ?? '';
    final String department = instructorData['department'] ?? '';
    final String office = instructorData['office'] ?? 'Bilinmiyor';
    final String email = instructorData['email'] ?? 'iletisim@iku.edu.tr';

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
                    child: Text(
                      getInitials(name),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppBadge(label: title, backgroundColor: AppTheme.primaryColor, textColor: Colors.white),
                  const SizedBox(height: 8),
                  Text(department, style: TextStyle(fontSize: 16, color: mutedColor)),
                  const SizedBox(height: 4),
                  Text("Ofis: $office", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // E-POSTA KUTUSU (Kopyalanabilir yapıldı)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Panoya kopyalama işlemi
                  Clipboard.setData(ClipboardData(text: email)).then((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("E-posta adresi kopyalandı!"),
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
                      // Tıklanabilir olduğunu belli eden ikon eklendi
                      Icon(Icons.copy, size: 18, color: mutedColor),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const SectionHeader(title: "Ofis Saatleri"),
            Card(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildOfficeHourRow(context, "Pazartesi", "10:00 - 12:00"),
                  const Divider(height: 1),
                  _buildOfficeHourRow(context, "Çarşamba", "14:00 - 16:00"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeHourRow(BuildContext context, String day, String time) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: textColor)),
          Text(time, style: TextStyle(color: mutedColor, fontSize: 14)),
        ],
      ),
    );
  }
}