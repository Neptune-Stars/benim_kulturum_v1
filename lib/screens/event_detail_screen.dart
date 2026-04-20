import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import '../providers/favorites_provider.dart';
import '../providers/joined_events_provider.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case "academic":
        return "Akademik";
      case "cultural":
        return "Kültürel";
      case "sports":
        return "Spor";
      case "social":
        return "Sosyal";
      default:
        return "Genel";
    }
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final joinedProvider = context.watch<JoinedEventsProvider>();

    final isFav = favProvider.isFavorite("evt_${event.id}");
    final isJoined = joinedProvider.isJoined(event.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final softBoxColor = isDark
        ? Colors.white.withOpacity(0.06)
        : AppTheme.primaryLight.withOpacity(0.10);
    final softBorderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : AppTheme.primaryLight.withOpacity(0.30);

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
                color: softBoxColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: softBorderColor),
              ),
              child: Column(
                children: [
                  AppBadge(
                    label: _getCategoryLabel(event.category),
                    backgroundColor: AppTheme.primaryColor,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  if (isJoined)
                    AppBadge(
                      label: "Katıldın",
                      backgroundColor: AppTheme.successColor.withOpacity(0.15),
                      textColor: AppTheme.successColor,
                    ),
                  if (isJoined) const SizedBox(height: 16),
                  Text(
                    event.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              "Tarih",
              event.date,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              Icons.access_time,
              "Saat",
              event.time,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              Icons.location_on,
              "Konum",
              event.location,
            ),
            const SizedBox(height: 32),
            Text(
              "Açıklama",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 16,
                color: mutedColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined
                      ? AppTheme.destructiveColor
                      : AppTheme.primaryColor,
                ),
                onPressed: () {
                  final alreadyJoined =
                  context.read<JoinedEventsProvider>().isJoined(event.id);

                  context.read<JoinedEventsProvider>().toggleJoin(event.id);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        alreadyJoined
                            ? "Etkinlik kaydın iptal edildi."
                            : "Etkinliğe katıldın. Artık Etkinliklerim bölümünde görünüyor.",
                      ),
                    ),
                  );
                },
                icon: Icon(
                  isJoined ? Icons.event_busy : Icons.event_available,
                ),
                label: Text(
                  isJoined ? "Katılımı İptal Et" : "Etkinliğe Katıl",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => context
                    .read<FavoritesProvider>()
                    .toggleFavorite("evt_${event.id}"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav
                      ? AppTheme.warningColor
                      : textColor,
                ),
                label: Text(
                  isFav ? "Favorilerden Çıkar" : "Favorilere Ekle",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final boxColor = isDark
        ? Colors.white.withOpacity(0.06)
        : AppTheme.backgroundColor;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: mutedColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ],
        )
      ],
    );
  }
}