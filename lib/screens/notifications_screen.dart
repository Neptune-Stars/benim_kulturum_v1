import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_header.dart';


class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationsStream() {
    return _db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _markAllAsRead() async {
    final snapshot = await _db
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  String _formatTime(dynamic value) {
    if (value == null) return "";

    DateTime? dateTime;

    if (value is Timestamp) {
      dateTime = value.toDate();
    } else if (value is DateTime) {
      dateTime = value;
    }

    if (dateTime == null) return "";

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays} days ago";

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();

    return "$day/$month/$year";
  }

  String _groupTitle(dynamic value) {
    if (value == null) return "Earlier";

    DateTime? dateTime;

    if (value is Timestamp) {
      dateTime = value.toDate();
    } else if (value is DateTime) {
      dateTime = value;
    }

    if (dateTime == null) return "Earlier";

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final notificationDay = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    final diffDays = today.difference(notificationDay).inDays;

    if (diffDays == 0) return "Today";
    if (diffDays <= 7) return "This Week";

    return "Earlier";
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'announcement':
        return Icons.campaign;
      case 'event':
        return Icons.event;
      case 'menu':
        return Icons.restaurant;
      case 'issue':
        return Icons.report_problem;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'announcement':
        return AppTheme.primaryColor;
      case 'event':
        return AppTheme.secondaryColor;
      case 'menu':
        return AppTheme.warningColor;
      case 'issue':
        return AppTheme.destructiveColor;
      default:
        return AppTheme.primaryLight;
    }
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _groupNotifications(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    grouped = {
      "Today": [],
      "This Week": [],
      "Earlier": [],
    };

    for (final doc in docs) {
      final data = doc.data();
      final group = _groupTitle(data['createdAt']);

      grouped.putIfAbsent(group, () => []);
      grouped[group]!.add(doc);
    }

    return grouped;
  }

  Future<void> _confirmAndDeleteNotification(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Notification"),
        content: const Text("Are you sure you want to delete this notification?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: AppTheme.destructiveColor),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Notifications",
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppTheme.primaryColor),
            tooltip: "Mark All as Read",
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _notificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Failed to load notifications: ${snapshot.error}"),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet.",
                style: TextStyle(color: AppTheme.textMuted),
              ),
            );
          }

          final grouped = _groupNotifications(docs);

          return ListView(
            children: [
              if (grouped["Today"]!.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SectionHeader(title: "Today"),
                ),
                ...grouped["Today"]!.map((doc) => _buildNotificationRow(doc)),
              ],
              if (grouped["This Week"]!.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SectionHeader(title: "This Week"),
                ),
                ...grouped["This Week"]!.map((doc) => _buildNotificationRow(doc)),
              ],
              if (grouped["Earlier"]!.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SectionHeader(title: "Earlier"),
                ),
                ...grouped["Earlier"]!
                    .map((doc) => _buildNotificationRow(doc)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationRow(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();

    final title = data["title"]?.toString() ?? "";
    final subtitle = data["subtitle"]?.toString() ?? "";
    final type = data["type"]?.toString() ?? "general";
    final isRead = data["isRead"] == true;
    final createdAt = data["createdAt"];

    final color = _colorForType(type);

    return InkWell(
      onTap: () async {
        if (!isRead) {
          await doc.reference.update({'isRead': true});
        }
      },
      child: Container(
        color:
        isRead ? Colors.transparent : AppTheme.primaryLight.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForType(type),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                      isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(createdAt),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.destructiveColor,
                    size: 22,
                  ),
                  tooltip: "Delete notification",
                  onPressed: () => _confirmAndDeleteNotification(doc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}