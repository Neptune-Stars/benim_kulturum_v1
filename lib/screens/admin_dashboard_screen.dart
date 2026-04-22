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

  // TAB İSMİ DEĞİŞTİ: Binalar -> Birimler
  final List<String> _tabs = [
    "Genel", "Birimler", "Derslikler", "Hocalar", "Etkinlikler", "Duyurular", "Yemekhane", "Fiyatlar", "Sorunlar", "Öğrenciler"
  ];

  final Map<int, TextEditingController> _searchControllers = {
    1: TextEditingController(), 2: TextEditingController(), 3: TextEditingController(),
    4: TextEditingController(), 5: TextEditingController(), 6: TextEditingController(),
    7: TextEditingController(), 8: TextEditingController(), 9: TextEditingController(),
  };

  final List<Map<String, String>> _mockPrices = [
    {"name": "Çay", "price": "₺3", "category": "Çay/Kahve"},
    {"name": "Türk Kahvesi", "price": "₺12", "category": "Çay/Kahve"},
    {"name": "Ayran", "price": "₺5", "category": "İçecekler"},
    {"name": "Tost", "price": "₺15", "category": "Atıştırmalıklar"},
    {"name": "Öğle Menüsü", "price": "₺35", "category": "Yemek"},
  ];

  final List<Map<String, dynamic>> _mockIssues = [
    {
      "id": 1, "category": "Altyapı Sorunu", "priority": "Yüksek", "subject": "Sınıfta projeksiyon çalışmıyor", "location": "MF-101",
      "description": "Bilgisayarı bağladığımızda görüntü gelmiyor, kablo kopuk olabilir.", "date": "Bugün 10:30"
    },
    {
      "id": 2, "category": "Temizlik", "priority": "Orta", "subject": "Lavabolarda sabun bitti", "location": "İİBF 2. Kat",
      "description": "Erkekler tuvaletindeki sıvı sabunluklar tamamen boşalmış.", "date": "Dün 14:15"
    },
  ];

  final List<Map<String, String>> _mockStudents = [
    {"name": "Ahmet Yılmaz", "no": "20210001234", "email": "ahmet@uni.edu.tr", "grade": "3. Sınıf"},
    {"name": "Ayşe Demir", "no": "20220005678", "email": "ayse@uni.edu.tr", "grade": "2. Sınıf"},
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
    for (var controller in _searchControllers.values) { controller.dispose(); }
    _tabController.dispose();
    super.dispose();
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    context.go('/login');
  }

  void _switchTab(int index) { _tabController.animateTo(index); }

  String _normalizeForSearch(String text) {
    return text.toLowerCase().replaceAll('i̇', 'i').replaceAll('ı', 'i').replaceAll('ğ', 'g')
        .replaceAll('ü', 'u').replaceAll('ş', 's').replaceAll('ö', 'o').replaceAll('ç', 'c');
  }

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

  void _showFormDialog({required String title, required List<Widget> fields}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child: f)).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydedildi (Demo)")));
              },
              child: const Text("Kaydet")
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, {bool isNumber = false, int lines = 1, bool isPassword = false}) {
    return TextField(
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: lines, obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (val) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor), SizedBox(width: 8), Text("Yönetici Paneli")]),
        centerTitle: false,
        actions: [IconButton(icon: const Icon(Icons.logout, color: AppTheme.destructiveColor), onPressed: _logout)],
        bottom: TabBar(
          controller: _tabController, isScrollable: true,
          labelColor: AppTheme.primaryColor, unselectedLabelColor: AppTheme.textMuted, indicatorColor: AppTheme.primaryColor,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _databaseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Gösterilecek veri bulunamadı."));

          final data = snapshot.data!;
          final allBuildings = data['buildings'] as List<dynamic>? ?? [];
          final allClassrooms = data['classrooms'] as List<dynamic>? ?? [];
          final allInstructors = data['instructors'] as List<dynamic>? ?? [];
          final allEvents = data['events'] as List<dynamic>? ?? [];
          final allAnnouncements = data['announcements'] as List<dynamic>? ?? [];

          final sq1 = _normalizeForSearch(_searchControllers[1]!.text);
          final filteredBuildings = allBuildings.where((b) => _normalizeForSearch(b['name'] ?? '').contains(sq1) || _normalizeForSearch(b['location'] ?? '').contains(sq1)).toList();

          final sq2 = _normalizeForSearch(_searchControllers[2]!.text);
          final filteredClassrooms = allClassrooms.where((c) => _normalizeForSearch(c['name'] ?? '').contains(sq2) || _normalizeForSearch(c['building'] ?? '').contains(sq2)).toList();

          final sq3 = _normalizeForSearch(_searchControllers[3]!.text);
          final filteredInstructors = allInstructors.where((i) => _normalizeForSearch(i['name'] ?? '').contains(sq3) || _normalizeForSearch(i['department'] ?? '').contains(sq3)).toList();

          final sq4 = _normalizeForSearch(_searchControllers[4]!.text);
          final filteredEvents = allEvents.where((e) => _normalizeForSearch(e['title'] ?? '').contains(sq4) || _normalizeForSearch(e['date'] ?? '').contains(sq4)).toList();

          final sq5 = _normalizeForSearch(_searchControllers[5]!.text);
          final filteredAnnouncements = allAnnouncements.where((a) => _normalizeForSearch(a['title'] ?? '').contains(sq5) || _normalizeForSearch(a['date'] ?? '').contains(sq5)).toList();

          final cafeteriaData = data['cafeteria'] as Map<dynamic, dynamic>? ?? {};
          final menus = cafeteriaData['menus'] as Map<dynamic, dynamic>? ?? {};
          final mealTypes = (cafeteriaData['mealTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ["Kahvaltı", "Öğle", "Akşam"];

          final sq6 = _normalizeForSearch(_searchControllers[6]!.text);
          final filteredMeals = mealTypes.where((m) => _normalizeForSearch(m).contains(sq6)).toList();

          final sq7 = _normalizeForSearch(_searchControllers[7]!.text);
          final filteredPrices = _mockPrices.where((p) => _normalizeForSearch(p["name"]!).contains(sq7) || _normalizeForSearch(p["category"]!).contains(sq7)).toList();

          final sq8 = _normalizeForSearch(_searchControllers[8]!.text);
          final filteredIssues = _mockIssues.where((iss) => _normalizeForSearch(iss["subject"]).contains(sq8) || _normalizeForSearch(iss["category"]).contains(sq8) || _normalizeForSearch(iss["location"]).contains(sq8)).toList();

          final sq9 = _normalizeForSearch(_searchControllers[9]!.text);
          final filteredStudents = _mockStudents.where((s) => _normalizeForSearch(s["name"]!).contains(sq9) || _normalizeForSearch(s["no"]!).contains(sq9)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildGenelTab(data),
              _buildManagementTab(
                title: "Kampüs Birimleri", count: filteredBuildings.length, searchController: _searchControllers[1]!,
                items: filteredBuildings.asMap().entries.map((e) => _buildListItem(e.value['name'] ?? '', e.value['location'] ?? '', () => _openBuildingForm(isEdit: true, item: e.value, index: e.key), () => _showDeleteDialog('buildings', e.key))).toList(),
                onAdd: () => _openBuildingForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Derslikler", count: filteredClassrooms.length, searchController: _searchControllers[2]!,
                items: filteredClassrooms.asMap().entries.map((e) => _buildListItem(e.value['name'] ?? '', e.value['building'] ?? '', () => _openClassroomForm(isEdit: true, item: e.value, index: e.key), () => _showDeleteDialog('classrooms', e.key))).toList(),
                onAdd: () => _openClassroomForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Hocalar", count: filteredInstructors.length, searchController: _searchControllers[3]!,
                items: filteredInstructors.asMap().entries.map((e) => _buildListItem(e.value['name'] ?? '', e.value['department'] ?? '', () => _openInstructorForm(isEdit: true, item: e.value, index: e.key), () => _showDeleteDialog('instructors', e.key))).toList(),
                onAdd: () => _openInstructorForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Etkinlikler", count: filteredEvents.length, searchController: _searchControllers[4]!,
                items: filteredEvents.asMap().entries.map((e) => _buildListItem(e.value['title'] ?? '', "${e.value['date']} - ${e.value['location']}", () => _openEventForm(isEdit: true, item: e.value, index: e.key), () => _showDeleteDialog('events', e.key))).toList(),
                onAdd: () => _openEventForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Duyurular", count: filteredAnnouncements.length, searchController: _searchControllers[5]!,
                items: filteredAnnouncements.asMap().entries.map((e) => _buildListItem(e.value['title'] ?? '', e.value['date'] ?? '', () => _openAnnouncementForm(isEdit: true, item: e.value, index: e.key), () => _showDeleteDialog('announcements', e.key))).toList(),
                onAdd: () => _openAnnouncementForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Yemekhane Menüleri", count: filteredMeals.length, searchController: _searchControllers[6]!,
                items: filteredMeals.map((meal) {
                  final menu = menus[meal] ?? {};
                  return _buildListItem(meal, "Saat: ${menu['time'] ?? '-'} | Fiyat: ${menu['price'] ?? '-'}", () => _openMenuForm(mealName: meal, item: menu, fullCafeteriaData: cafeteriaData), null);
                }).toList(),
                onAdd: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yeni öğün eklenemez, mevcutları düzenleyin."))),
              ),
              _buildManagementTab(
                title: "Fiyatlar", count: filteredPrices.length, searchController: _searchControllers[7]!,
                items: filteredPrices.map((p) => _buildListItem(p["name"]!, "${p["price"]} - ${p["category"]}", () => _openPriceForm(isEdit: true), null)).toList(),
                onAdd: () => _openPriceForm(isEdit: false),
              ),
              _buildIssuesTab(filteredIssues, _searchControllers[8]!),
              _buildManagementTab(
                title: "Öğrenciler", count: filteredStudents.length, searchController: _searchControllers[9]!,
                items: filteredStudents.map((s) => _buildListItem(s["name"]!, "${s["no"]} - ${s["grade"]}", () => _openStudentForm(isEdit: true), null)).toList(),
                onAdd: () => _openStudentForm(isEdit: false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGenelTab(Map<String, dynamic> data) {
    final bCount = (data['buildings'] as List?)?.length ?? 0;
    final cCount = (data['classrooms'] as List?)?.length ?? 0;
    final iCount = (data['instructors'] as List?)?.length ?? 0;

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
                Expanded(child: Text("Yerel Veritabanı (Hive) Aktif", style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.25,
            children: [
              _buildStatCard(Icons.business, "Birimler", bCount.toString(), 1), // İsmi Binalar yerine Birimler oldu
              _buildStatCard(Icons.meeting_room, "Derslikler", cCount.toString(), 2),
              _buildStatCard(Icons.people, "Hocalar", iCount.toString(), 3),
              _buildStatCard(Icons.event, "Etkinlikler", ((data['events'] as List?)?.length ?? 0).toString(), 4),
              _buildStatCard(Icons.report_problem, "Sorunlar", _mockIssues.length.toString(), 8),
              _buildStatCard(Icons.person, "Öğrenciler", _mockStudents.length.toString(), 9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, int tabIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _switchTab(tabIndex),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              // Sınır çizgisini de karanlık moda uyumlu hale getirelim
                color: isDark ? Colors.white.withOpacity(0.1) : AppTheme.borderColor
            )
        ),
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

  Widget _buildManagementTab({required String title, required int count, required List<Widget> items, required VoidCallback onAdd, required TextEditingController searchController}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$title ($count)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text("Ekle"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AppSearchBar(
            controller: searchController, placeholder: "Ara...", onChanged: (val) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: items.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (context, index) => items[index],
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

  Widget _buildIssuesTab(List<Map<String, dynamic>> issues, TextEditingController searchController) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Gelen Sorunlar (${issues.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AppSearchBar(controller: searchController, placeholder: "Konu veya konum ara...", onChanged: (val) => setState(() {})),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: issues.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final issue = issues[index];
              Color priorityColor = issue["priority"] == "Yüksek" ? AppTheme.destructiveColor : (issue["priority"] == "Orta" ? AppTheme.warningColor : AppTheme.successColor);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(issue["priority"], style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(issue["subject"], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text("${issue["category"]} • ${issue["location"]}\n${issue["date"]}", style: const TextStyle(color: AppTheme.textMuted))),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.remove_red_eye, color: AppTheme.primaryLight), onPressed: () => _openIssueDetailsDialog(issue)),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  void _openIssueDetailsDialog(Map<String, dynamic> issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sorun Detayı", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Konu: ${issue["subject"]}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Text("Kategori: ${issue["category"]}", style: const TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text("Konum: ${issue["location"]}", style: const TextStyle(color: AppTheme.textMuted)),
              const Divider(height: 24),
              Text(issue["description"], style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Çözüldü işaretlendi."))); },
            icon: const Icon(Icons.check, size: 18), label: const Text("Çözüldü"),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openStudentForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Öğrenci" : "Yeni Öğrenci Ekle",
        fields: [
          _buildTextField("Ad Soyad"), _buildTextField("Öğrenci No", isNumber: true),
          _buildTextField("E-posta"), _buildTextField("Şifre", isPassword: true),
          _buildDropdown("Sınıf", ["Hazırlık", "1. Sınıf", "2. Sınıf", "3. Sınıf", "4. Sınıf", "Mezun"]),
        ]
    );
  }

  void _openPriceForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Fiyat" : "Yeni Fiyat Ekle",
        fields: [
          _buildDropdown("Kategori", ["Çay/Kahve", "İçecekler", "Atıştırmalıklar", "Yemek"]),
          _buildTextField("Ürün Adı"), _buildTextField("Fiyat (₺)", isNumber: true),
        ]
    );
  }

  // BİNALAR FORMU ARTIK BİRİMLER FORMU OLDU (Gereksiz inputlar silindi)
  void _openBuildingForm({required bool isEdit, Map<dynamic, dynamic>? item, int? index}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final locCtrl = TextEditingController(text: item?['location']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Düzenle: Birim/Alan" : "Yeni Birim Ekle", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Birim Adı (Örn: Hukuk Fakültesi)")),
            const SizedBox(height: 12),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: "Kampüs & Konum (Örn: Ataköy, 3. Kat)")),
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
                  'type': item?['type'] ?? 'faculty' // Varsayılan değer
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
            TextField(controller: buildCtrl, decoration: const InputDecoration(labelText: "Bağlı Olduğu Kampüs/Birim")),
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
                  'name': nameCtrl.text, 'building': buildCtrl.text,
                  'capacity': item?['capacity'] ?? 40, 'type': item?['type'] ?? 'Derslik', 'floor': item?['floor'] ?? 1
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
                  'name': nameCtrl.text, 'department': deptCtrl.text,
                  'title': item?['title'] ?? 'Öğretim Üyesi', 'office': item?['office'] ?? 'Bilinmiyor', 'filter': item?['filter'] ?? 'engineering'
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
                  'title': titleCtrl.text, 'date': dateCtrl.text, 'location': locCtrl.text,
                  'category': item?['category'] ?? 'Genel', 'description': item?['description'] ?? 'Detay girilmedi.'
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
                  'title': titleCtrl.text, 'date': dateCtrl.text, 'content': contentCtrl.text, 'category': item?['category'] ?? 'Genel'
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
            TextField(controller: itemsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Yemekler (Virgülle ayırın)", hintText: "Çorba, Pilav, Salata")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
              onPressed: () async {
                List<String> newItems = itemsCtrl.text.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                fullCafeteriaData['menus'][mealName] = {
                  'time': timeCtrl.text, 'price': priceCtrl.text, 'items': newItems, 'isChips': item['isChips'] ?? false,
                };
                var box = Hive.box('campusDataBox');
                await box.put('cafeteria', fullCafeteriaData);
                if (context.mounted) { Navigator.pop(context); _loadData(); }
              },
              child: const Text("Kaydet")
          )
        ],
      ),
    );
  }
}