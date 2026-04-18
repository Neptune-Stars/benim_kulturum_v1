import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import '../providers/favorites_provider.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  String _getCategoryLabel(String cat) {
    switch(cat) {
      case "academic": return "Akademik";
      case "cultural": return "Kültürel";
      case "sports": return "Spor";
      case "social": return "Sosyal";
      default: return "Genel";
    }
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite("evt_${event.id}");

    return Scaffold(
      appBar: CustomAppBar(title: event.title, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  AppBadge(
                    label: _getCategoryLabel(event.category),
                    backgroundColor: AppTheme.primaryColor,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.calendar_today, "Tarih", event.date),
            const Divider(height: 24),
            _buildDetailRow(Icons.access_time, "Saat", event.time),
            const Divider(height: 24),
            _buildDetailRow(Icons.location_on, "Konum", event.location),
            const SizedBox(height: 32),
            const Text(
              "Açıklama",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(fontSize: 16, color: AppTheme.textMuted, height: 1.5),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Etkinliğe katılım talebiniz alındı!")),
                  );
                },
                child: const Text("Etkinliğe Katıl", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => context.read<FavoritesProvider>().toggleFavorite("evt_${event.id}"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? AppTheme.warningColor : AppTheme.textPrimary),
                label: Text(isFav ? "Favorilerden Çıkar" : "Favorilere Ekle", style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        )
      ],
    );
  }
}