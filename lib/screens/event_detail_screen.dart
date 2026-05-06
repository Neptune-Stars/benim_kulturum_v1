import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import '../providers/favorites_provider.dart';
import '../providers/joined_events_provider.dart';

class EventDetailScreen extends StatelessWidget {
  final Map<dynamic, dynamic> eventData;

  const EventDetailScreen({Key? key, required this.eventData}) : super(key: key);

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case "academic": return "Academic";
      case "cultural": return "Cultural";
      case "sports": return "Sports";
      case "social": return "Social";
      default: return "General";
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = Map<String, dynamic>.from(eventData);

    final favProvider = context.watch<FavoritesProvider>();
    final joinedProvider = context.watch<JoinedEventsProvider>();

    final eventId = data['id'] is int ? data['id'] : int.tryParse(data['id'].toString()) ?? 0;
    final isFav = favProvider.isFavorite("evt_$eventId");

    final String title = data['title'] ?? 'Event';
    final String category = data['category'] ?? '';
    final String date = data['date'] ?? '';
    final String time = data['time'] ?? '';
    final String location = data['location'] ?? '';
    final String description = data['description'] ?? '';

    final isJoined = joinedProvider.isJoined(eventId);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final softBoxColor = isDark ? Colors.white.withOpacity(0.06) : AppTheme.primaryLight.withOpacity(0.10);
    final softBorderColor = isDark ? Colors.white.withOpacity(0.10) : AppTheme.primaryLight.withOpacity(0.30);

    return Scaffold(
      appBar: CustomAppBar(title: title, showBack: true),
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
                    label: _getCategoryLabel(category),
                    backgroundColor: AppTheme.primaryColor,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  if (isJoined)
                    AppBadge(
                      label: "Joined",
                      backgroundColor: AppTheme.successColor.withOpacity(0.15),
                      textColor: AppTheme.successColor,
                    ),
                  if (isJoined) const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(context, Icons.calendar_today, "Date", date),
            const Divider(height: 24),
            _buildDetailRow(context, Icons.access_time, "Time", time),
            const Divider(height: 24),
            _buildDetailRow(context, Icons.location_on, "Location", location),
            const SizedBox(height: 32),
            Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 16, color: AppTheme.textMuted, height: 1.5)),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined ? AppTheme.destructiveColor : AppTheme.primaryColor,
                ),
                onPressed: () {
                  final alreadyJoined = context.read<JoinedEventsProvider>().isJoined(eventId);
                  context.read<JoinedEventsProvider>().toggleJoin(eventId);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(alreadyJoined ? "Event registration cancelled." : "You have joined the event. It now appears in My Events."),
                    ),
                  );
                },
                icon: Icon(isJoined ? Icons.event_busy : Icons.event_available),
                label: Text(
                  isJoined ? "Cancel Registration" : "Join Event",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => context.read<FavoritesProvider>().toggleFavorite("evt_$eventId"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? AppTheme.warningColor : textColor,
                ),
                label: Text(isFav ? "Remove from Favorites" : "Add to Favorites", style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final boxColor = isDark ? Colors.white.withOpacity(0.06) : AppTheme.backgroundColor;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: boxColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: mutedColor, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
          ],
        )
      ],
    );
  }
}