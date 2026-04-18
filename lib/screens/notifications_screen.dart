import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock inline data for notifications
  final List<Map<String, dynamic>> _notifications = [
    {
      "id": 1, "title": "Burs Başvuruları", "subtitle": "2026 Bahar dönemi burs başvuruları başladı.",
      "time": "10 dk önce", "icon": Icons.attach_money, "color": AppTheme.successColor, "isRead": false, "group": "Bugün"
    },
    {
      "id": 2, "title": "Yeni Menü Eklendi", "subtitle": "Bugünün öğle yemeği menüsü güncellendi.",
      "time": "2 saat önce", "icon": Icons.restaurant, "color": AppTheme.warningColor, "isRead": false, "group": "Bugün"
    },
    {
      "id": 3, "title": "Vize Sınavı Programı", "subtitle": "Vize sınavı programı öğrenci bilgi sisteminde yayınlandı.",
      "time": "Dün", "icon": Icons.school, "color": AppTheme.primaryColor, "isRead": true, "group": "Bu Hafta"
    },
    {
      "id": 4, "title": "Kütüphane Çalışma Saatleri", "subtitle": "Kütüphane hafta sonu 24 saat açık olacaktır.",
      "time": "3 gün önce", "icon": Icons.menu_book, "color": AppTheme.secondaryColor, "isRead": true, "group": "Bu Hafta"
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n["isRead"] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayList = _notifications.where((n) => n["group"] == "Bugün").toList();
    final weekList = _notifications.where((n) => n["group"] == "Bu Hafta").toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: "Bildirimler",
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppTheme.primaryColor),
            tooltip: "Tümünü Okundu İşaretle",
            onPressed: _markAllAsRead,
          )
        ],
      ),
      body: ListView(
        children: [
          if (todayList.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SectionHeader(title: "Bugün"),
            ),
            ...todayList.map((n) => _buildNotificationRow(n)),
          ],
          if (weekList.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SectionHeader(title: "Bu Hafta"),
            ),
            ...weekList.map((n) => _buildNotificationRow(n)),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationRow(Map<String, dynamic> n) {
    final bool isRead = n["isRead"];
    return Container(
      color: isRead ? Colors.transparent : AppTheme.primaryLight.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (n["color"] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(n["icon"] as IconData, color: n["color"] as Color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n["title"], style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(n["subtitle"], style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                const SizedBox(height: 8),
                Text(n["time"], style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: AppTheme.primaryLight, shape: BoxShape.circle),
            )
        ],
      ),
    );
  }
}