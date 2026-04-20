import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/data_service.dart';
import '../../widgets/search_bar_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _tabs = [
    "Genel", "Binalar", "Derslikler", "Hocalar", "Etkinlikler", "Duyurular", "Yemekhane"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _databaseFuture = DataService.loadDatabase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    context.go('/login');
  }

  void _switchTab(int index) {
    _tabController.animateTo(index);
  }

  // Ortak Silme Fonksiyonu
  void _showDeleteDialog(String collectionKey, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Silmeyi Onayla"),
        content: const Text("Bu kaydı silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
              onPressed: () async {
                var box = Hive.box('campusDataBox');
                List currentList = List.from(box.get(collectionKey, defaultValue: []));

                currentList.removeAt(index);
                await box.put(collectionKey, currentList);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt veritabanından silindi.")));
                  _loadData();
                }
              },
              child: const Text("Sil", style: TextStyle(color: AppTheme.destructiveColor))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text("Yönetici Paneli"),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: AppTheme.destructiveColor), onPressed: _logout)
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryColor,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _databaseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Veri yüklenemedi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Gösterilecek veri bulunamadı."));
          }

          final data = snapshot.data!;
          final buildings = data['buildings'] as List<dynamic>? ?? [];
          final classrooms = data['classrooms'] as List<dynamic>? ?? [];
          final instructors = data['instructors'] as List<dynamic>? ?? [];
          final events = data['events'] as List<dynamic>? ?? [];
          final announcements = data['announcements'] as List<dynamic>? ?? [];

          // Yemekhane verilerini çözümleme
          final cafeteriaData = data['cafeteria'] as Map<dynamic, dynamic>? ?? {};
          final menus = cafeteriaData['menus'] as Map<dynamic, dynamic>? ?? {};
          final mealTypes = (cafeteriaData['mealTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ["Kahvaltı", "Öğle", "Akşam"];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildGenelTab(data),

              // 1. BİNALAR
              _buildManagementTab(
                title: "Binalar",
                count: buildings.length,
                items: buildings.asMap().entries.map((e) => _buildListItem(
                    e.value['name'] ?? '', e.value['location'] ?? '',
                        () => _openBuildingForm(isEdit: true, item: e.value, index: e.key), () => _showDeleteDialog('buildings', e.key)
                )).toList(),
                onAdd: () => _openBuildingForm(isEdit: false),
              ),

              // 2. DERSLİKLER
              _buildManagementTab(
                title: "Derslikler",
                count: classrooms.length,
                items: classrooms.asMap().entries.map((e) => _buildListItem(
                    e.value['name'] ?? '', e.value['building'] ?? '',
                        () => _openClassroomForm(isEdit: true, item: e.value, index: e.key), () => _showDeleteDialog('classrooms', e.key)
                )).toList(),
                onAdd: () => _openClassroomForm(isEdit: false),
              ),

              // 3. HOCALAR
              _buildManagementTab(
                title: "Hocalar",
                count: instructors.length,
                items: instructors.asMap().entries.map((e) => _buildListItem(
                    e.value['name'] ?? '', e.value['department'] ?? '',
                        () => _openInstructorForm(isEdit: true, item: e.value, index: e.key), () => _showDeleteDialog('instructors', e.key)
                )).toList(),
                onAdd: () => _openInstructorForm(isEdit: false),
              ),

              // 4. ETKİNLİKLER
              _buildManagementTab(
                title: "Etkinlikler",
                count: events.length,
                items: events.asMap().entries.map((e) => _buildListItem(
                    e.value['title'] ?? '', "${e.value['date']} - ${e.value['location']}",
                        () => _openEventForm(isEdit: true, item: e.value, index: e.key), () => _showDeleteDialog('events', e.key)
                )).toList(),
                onAdd: () => _openEventForm(isEdit: false),
              ),

              // 5. DUYURULAR
              _buildManagementTab(
                title: "Duyurular",
                count: announcements.length,
                items: announcements.asMap().entries.map((e) => _buildListItem(
                    e.value['title'] ?? '', e.value['date'] ?? '',
                        () => _openAnnouncementForm(isEdit: true, item: e.value, index: e.key), () => _showDeleteDialog('announcements', e.key)
                )).toList(),
                onAdd: () => _openAnnouncementForm(isEdit: false),
              ),

              // 6. YEMEKHANE (Özel Yapı)
              _buildManagementTab(
                title: "Yemekhane Menüleri",
                count: mealTypes.length,
                items: mealTypes.map((meal) {
                  final menu = menus[meal] ?? {};
                  return _buildListItem(
                      meal,
                      "Saat: ${menu['time'] ?? '-'} | Fiyat: ${menu['price'] ?? '-'}",
                          () => _openMenuForm(mealName: meal, item: menu, fullCafeteriaData: cafeteriaData),
                      null // Yemekhane öğünleri silinmez, sadece güncellenir
                  );
                }).toList(),
                onAdd: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yeni öğün eklenemez, mevcutları düzenleyin."))),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- SEKME İÇERİKLERİ ---

  Widget _buildGenelTab(Map<String, dynamic> data) {
    final bCount = (data['buildings'] as List?)?.length ?? 0;
    final cCount = (data['classrooms'] as List?)?.length ?? 0;
    final iCount = (data['instructors'] as List?)?.length ?? 0;
    final eCount = (data['events'] as List?)?.length ?? 0;
    final aCount = (data['announcements'] as List?)?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.successColor.withOpacity(0.3))),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successColor),
                SizedBox(width: 12),
                Expanded(child: Text("Yerel Veritabanı (Hive) Aktif ve Bağlı", style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(Icons.business, "Binalar", bCount.toString(), 1),
              _buildStatCard(Icons.meeting_room, "Derslikler", cCount.toString(), 2),
              _buildStatCard(Icons.people, "Hocalar", iCount.toString(), 3),
              _buildStatCard(Icons.event, "Etkinlikler", eCount.toString(), 4),
              _buildStatCard(Icons.campaign, "Duyurular", aCount.toString(), 5),
              _buildStatCard(Icons.restaurant, "Menü", "Güncel", 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, int tabIndex) {
    return InkWell(
      onTap: () => _switchTab(tabIndex),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Icon(icon, color: AppTheme.primaryColor), const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20)],
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTab({required String title, required int count, required List<Widget> items, required VoidCallback onAdd}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$title ($count)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Ekle"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) => items[index],
          ),
        )
      ],
    );
  }

  Widget _buildListItem(String title, String subtitle, VoidCallback onEdit, VoidCallback? onDelete) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            ],
          ),
        ),
        IconButton(icon: const Icon(Icons.edit, color: AppTheme.primaryLight), onPressed: onEdit),
        if (onDelete != null)
          IconButton(icon: const Icon(Icons.delete, color: AppTheme.destructiveColor), onPressed: onDelete),
      ],
    );
  }

  // --- GERÇEK VERİTABANI FORMLARI ---

  void _openBuildingForm({required bool isEdit, Map<dynamic, dynamic>? item, int? index}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final locCtrl = TextEditingController(text: item?['location']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Düzenle: Bina" : "Yeni Bina", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Bina Adı")),
            const SizedBox(height: 12),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: "Konum")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
              onPressed: () async {
                var box = Hive.box('campusDataBox');
                List list = List.from(box.get('buildings', defaultValue: []));

                Map<String, dynamic> newData = {
                  'id': isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch,
                  'name': nameCtrl.text,
                  'location': locCtrl.text,
                  'abbr': item?['abbr'] ?? 'YENİ',
                  'floors': item?['floors'] ?? 1,
                  'rooms': item?['rooms'] ?? 10,
                  'type': item?['type'] ?? 'academic'
                };

                if (isEdit) { list[index!] = newData; } else { list.add(newData); }
                await box.put('buildings', list);
                if (context.mounted) { Navigator.pop(context); _loadData(); }
              },
              child: const Text("Kaydet")
          )
        ],
      ),
    );
  }

  void _openClassroomForm({required bool isEdit, Map<dynamic, dynamic>? item, int? index}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final buildCtrl = TextEditingController(text: item?['building']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Düzenle: Derslik" : "Yeni Derslik", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Derslik Adı")),
            const SizedBox(height: 12),
            TextField(controller: buildCtrl, decoration: const InputDecoration(labelText: "Bağlı Olduğu Bina")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
              onPressed: () async {
                var box = Hive.box('campusDataBox');
                List list = List.from(box.get('classrooms', defaultValue: []));

                Map<String, dynamic> newData = {
                  'id': isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch,
                  'name': nameCtrl.text,
                  'building': buildCtrl.text,
                  'capacity': item?['capacity'] ?? 40,
                  'type': item?['type'] ?? 'Derslik',
                  'floor': item?['floor'] ?? 1
                };

                if (isEdit) { list[index!] = newData; } else { list.add(newData); }
                await box.put('classrooms', list);
                if (context.mounted) { Navigator.pop(context); _loadData(); }
              },
              child: const Text("Kaydet")
          )
        ],
      ),
    );
  }

  void _openInstructorForm({required bool isEdit, Map<dynamic, dynamic>? item, int? index}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final deptCtrl = TextEditingController(text: item?['department']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Düzenle: Hoca" : "Yeni Hoca", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Hoca Adı Soyadı")),
            const SizedBox(height: 12),
            TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: "Bölümü")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
              onPressed: () async {
                var box = Hive.box('campusDataBox');
                List list = List.from(box.get('instructors', defaultValue: []));

                Map<String, dynamic> newData = {
                  'id': isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch,
                  'name': nameCtrl.text,
                  'department': deptCtrl.text,
                  'title': item?['title'] ?? 'Öğretim Üyesi',
                  'office': item?['office'] ?? 'Bilinmiyor',
                  'filter': item?['filter'] ?? 'engineering'
                };

                if (isEdit) { list[index!] = newData; } else { list.add(newData); }
                await box.put('instructors', list);
                if (context.mounted) { Navigator.pop(context); _loadData(); }
              },
              child: const Text("Kaydet")
          )
        ],
      ),
    );
  }

  void _openEventForm({required bool isEdit, Map<dynamic, dynamic>? item, int? index}) {
    final titleCtrl = TextEditingController(text: item?['title']);
    final dateCtrl = TextEditingController(text: item?['date']);
    final locCtrl = TextEditingController(text: item?['location']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Düzenle: Etkinlik" : "Yeni Etkinlik", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Etkinlik Başlığı")),
            const SizedBox(height: 12),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Tarih (Örn: 20 Nisan, 14:00)")),
            const SizedBox(height: 12),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: "Konum")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
              onPressed: () async {
                var box = Hive.box('campusDataBox');
                List list = List.from(box.get('events', defaultValue: []));

                Map<String, dynamic> newData = {
                  'id': isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch,
                  'title': titleCtrl.text,
                  'date': dateCtrl.text,
                  'location': locCtrl.text,
                  'category': item?['category'] ?? 'Genel',
                  'description': item?['description'] ?? 'Detay girilmedi.'
                };

                if (isEdit) { list[index!] = newData; } else { list.add(newData); }
                await box.put('events', list);
                if (context.mounted) { Navigator.pop(context); _loadData(); }
              },
              child: const Text("Kaydet")
          )
        ],
      ),
    );
  }

  void _openAnnouncementForm({required bool isEdit, Map<dynamic, dynamic>? item, int? index}) {
    final titleCtrl = TextEditingController(text: item?['title']);
    final dateCtrl = TextEditingController(text: item?['date']);
    final contentCtrl = TextEditingController(text: item?['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Düzenle: Duyuru" : "Yeni Duyuru", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Başlık")),
            const SizedBox(height: 12),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Tarih (Örn: 18 Nisan)")),
            const SizedBox(height: 12),
            TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "İçerik")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
              onPressed: () async {
                var box = Hive.box('campusDataBox');
                List list = List.from(box.get('announcements', defaultValue: []));

                Map<String, dynamic> newData = {
                  'id': isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch,
                  'title': titleCtrl.text,
                  'date': dateCtrl.text,
                  'content': contentCtrl.text,
                  'category': item?['category'] ?? 'Genel'
                };

                if (isEdit) { list[index!] = newData; } else { list.add(newData); }
                await box.put('announcements', list);
                if (context.mounted) { Navigator.pop(context); _loadData(); }
              },
              child: const Text("Kaydet")
          )
        ],
      ),
    );
  }

  void _openMenuForm({required String mealName, required Map<dynamic, dynamic> item, required Map<dynamic, dynamic> fullCafeteriaData}) {
    final timeCtrl = TextEditingController(text: item['time']);
    final priceCtrl = TextEditingController(text: item['price']);
    // Liste olan yemekleri text'e çevirip virgülle ayırıyoruz
    final itemsListText = (item['items'] as List<dynamic>? ?? []).join(", ");
    final itemsCtrl = TextEditingController(text: itemsListText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Menü Düzenle: $mealName", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: "Saat Aralığı (Örn: 12:00-14:00)")),
            const SizedBox(height: 12),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: "Fiyat (Örn: ₺35)")),
            const SizedBox(height: 12),
            TextField(
              controller: itemsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Yemekler (Virgülle ayırın)", hintText: "Çorba, Pilav, Salata"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
              onPressed: () async {
                // Virgülle ayrılmış yazıyı tekrar listeye çeviriyoruz
                List<String> newItems = itemsCtrl.text.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                // Sadece ilgili öğünü (Örn: Öğle) güncelliyoruz
                fullCafeteriaData['menus'][mealName] = {
                  'time': timeCtrl.text,
                  'price': priceCtrl.text,
                  'items': newItems,
                  'isChips': item['isChips'] ?? false,
                };

                var box = Hive.box('campusDataBox');
                await box.put('cafeteria', fullCafeteriaData); // Tüm menüyü tekrar kaydediyoruz

                if (context.mounted) { Navigator.pop(context); _loadData(); }
              },
              child: const Text("Kaydet")
          )
        ],
      ),
    );
  }
}