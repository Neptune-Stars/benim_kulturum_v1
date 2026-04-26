import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    "Genel", "Birimler", "Derslikler", "Hocalar", "Etkinlikler", "Duyurular", "Yemekhane", "Fiyatlar", "Sorunlar", "Öğrenciler"
  ];

  final Map<int, TextEditingController> _searchControllers = {
    1: TextEditingController(), 2: TextEditingController(), 3: TextEditingController(),
    4: TextEditingController(), 5: TextEditingController(), 6: TextEditingController(),
    7: TextEditingController(), 8: TextEditingController(), 9: TextEditingController(),
  };

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

  void _showDeleteDialog(String collectionKey, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Silmeyi Onayla"),
        content: const Text("Bu kaydı silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection(collectionKey).doc(docId).delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt bulut veritabanından silindi.")));
                  _loadData();
                }
              },
              child: const Text("Sil", style: TextStyle(color: AppTheme.destructiveColor))
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, {bool isNumber = false, int lines = 1, bool isPassword = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: lines, obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, {String? value, Function(String?)? onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged ?? (val) {},
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

          // NEW: Reading fully from Firebase now
          final allPrices = data['prices'] as List<dynamic>? ?? [];
          final allIssues = data['issues'] as List<dynamic>? ?? [];
          final allStudents = data['students'] as List<dynamic>? ?? [];

          final cafeteriaData = data['cafeteria'] as Map<dynamic, dynamic>? ?? {};
          final menus = cafeteriaData['menus'] as Map<dynamic, dynamic>? ?? {};
          final mealTypes = (cafeteriaData['mealTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ["Kahvaltı", "Öğle", "Akşam"];

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

          final sq6 = _normalizeForSearch(_searchControllers[6]!.text);
          final filteredMeals = mealTypes.where((m) => _normalizeForSearch(m).contains(sq6)).toList();

          final sq7 = _normalizeForSearch(_searchControllers[7]!.text);
          final filteredPrices = allPrices.where((p) => _normalizeForSearch(p["name"] ?? '').contains(sq7) || _normalizeForSearch(p["category"] ?? '').contains(sq7)).toList();

          final sq8 = _normalizeForSearch(_searchControllers[8]!.text);
          final filteredIssues = allIssues.where((iss) => _normalizeForSearch(iss["subject"] ?? '').contains(sq8) || _normalizeForSearch(iss["category"] ?? '').contains(sq8)).toList();

          final sq9 = _normalizeForSearch(_searchControllers[9]!.text);
          final filteredStudents = allStudents.where((s) => _normalizeForSearch(s["name"] ?? '').contains(sq9) || _normalizeForSearch(s["no"] ?? '').contains(sq9)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildGenelTab(data),
              _buildManagementTab(
                title: "Kampüs Birimleri", count: filteredBuildings.length, searchController: _searchControllers[1]!,
                items: filteredBuildings.map((e) => _buildListItem(e['name'] ?? '', e['location'] ?? '', () => _openBuildingForm(isEdit: true, item: e), () => _showDeleteDialog('buildings', e['id'].toString()))).toList(),
                onAdd: () => _openBuildingForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Derslikler", count: filteredClassrooms.length, searchController: _searchControllers[2]!,
                items: filteredClassrooms.map((e) => _buildListItem(e['name'] ?? '', e['building'] ?? '', () => _openClassroomForm(isEdit: true, item: e), () => _showDeleteDialog('classrooms', e['id'].toString()))).toList(),
                onAdd: () => _openClassroomForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Hocalar", count: filteredInstructors.length, searchController: _searchControllers[3]!,
                items: filteredInstructors.map((e) => _buildListItem(e['name'] ?? '', e['department'] ?? '', () => _openInstructorForm(isEdit: true, item: e), () => _showDeleteDialog('instructors', e['id'].toString()))).toList(),
                onAdd: () => _openInstructorForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Etkinlikler", count: filteredEvents.length, searchController: _searchControllers[4]!,
                items: filteredEvents.map((e) => _buildListItem(e['title'] ?? '', "${e['date']} - ${e['location']}", () => _openEventForm(isEdit: true, item: e), () => _showDeleteDialog('events', e['id'].toString()))).toList(),
                onAdd: () => _openEventForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Duyurular", count: filteredAnnouncements.length, searchController: _searchControllers[5]!,
                items: filteredAnnouncements.map((e) => _buildListItem(e['title'] ?? '', e['date'] ?? '', () => _openAnnouncementForm(isEdit: true, item: e), () => _showDeleteDialog('announcements', e['id'].toString()))).toList(),
                onAdd: () => _openAnnouncementForm(isEdit: false),
              ),
              // YENİ YEMEKHANE YÖNETİMİ
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Yemekhane Menü Yönetimi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Öğrenciler kampüs ve gün bazlı farklı menüler görürler. Menüleri düzenlemek için aşağıdan seçim yapın.", style: TextStyle(color: AppTheme.textMuted)),
                    const SizedBox(height: 16),
                    ...["Ataköy", "Şirinevler", "İncirli", "Basın Ekspres"].map((campus) {
                      return ExpansionTile(
                        title: Text("$campus Kampüsü", style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Hafta Sonu"].map((day) {
                          final campusData = (cafeteriaData['menus'] as Map?)?[campus] as Map?;
                          final dayData = (campusData?[day] as Map?) ?? {};

                          return ListTile(
                            title: Text(day),
                            subtitle: Text("${dayData.keys.length} Öğün Kayıtlı"),
                            trailing: const Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$campus - $day Düzenleme Modülü Yakında Eklenecek!")));
                            },
                          );
                        }).toList(),
                      );
                    }).toList()
                  ],
                ),
              ),
              _buildManagementTab(
                title: "Fiyatlar", count: filteredPrices.length, searchController: _searchControllers[7]!,
                items: filteredPrices.map((p) => _buildListItem(p["name"] ?? '', "${p["price"]} - ${p["category"]}", () => _openPriceForm(isEdit: true, item: p), () => _showDeleteDialog('prices', p['id'].toString()))).toList(),
                onAdd: () => _openPriceForm(isEdit: false),
              ),
              _buildIssuesTab(filteredIssues, _searchControllers[8]!),
              _buildManagementTab(
                title: "Öğrenciler", count: filteredStudents.length, searchController: _searchControllers[9]!,
                items: filteredStudents.map((s) => _buildListItem(s["name"] ?? '', "${s["no"]} - ${s["grade"]}", () => _openStudentForm(isEdit: true, item: s), () => _showDeleteDialog('students', s['id'].toString()))).toList(),
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
            decoration: BoxDecoration(color: AppTheme.primaryLight.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3))),
            child: const Row(
              children: [
                Icon(Icons.cloud_done, color: AppTheme.primaryColor),
                SizedBox(width: 12),
                Expanded(child: Text("Google Firebase Cloud Aktif", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.25,
            children: [
              _buildStatCard(Icons.business, "Birimler", bCount.toString(), 1),
              _buildStatCard(Icons.meeting_room, "Derslikler", cCount.toString(), 2),
              _buildStatCard(Icons.people, "Hocalar", iCount.toString(), 3),
              _buildStatCard(Icons.event, "Etkinlikler", ((data['events'] as List?)?.length ?? 0).toString(), 4),
              _buildStatCard(Icons.report_problem, "Sorunlar", ((data['issues'] as List?)?.length ?? 0).toString(), 8),
              _buildStatCard(Icons.person, "Öğrenciler", ((data['students'] as List?)?.length ?? 0).toString(), 9),
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
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : AppTheme.borderColor)
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
          child: AppSearchBar(controller: searchController, placeholder: "Ara...", onChanged: (val) => setState(() {})),
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

  Widget _buildIssuesTab(List<dynamic> issues, TextEditingController searchController) {
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
                      child: Text(issue["priority"] ?? '', style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(issue["subject"] ?? '', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text("${issue["category"]} • ${issue["location"]}\n${issue["date"]}", style: const TextStyle(color: AppTheme.textMuted))),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.remove_red_eye, color: AppTheme.primaryLight), onPressed: () => _openIssueDetailsDialog(issue)),
                    IconButton(icon: const Icon(Icons.delete, color: AppTheme.destructiveColor), onPressed: () => _showDeleteDialog('issues', issue['id'].toString())),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  void _openIssueDetailsDialog(Map<dynamic, dynamic> issue) {
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
              Text(issue["description"] ?? '', style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
          ElevatedButton.icon(
            onPressed: () async {
              // Delete issue when resolved
              await FirebaseFirestore.instance.collection('issues').doc(issue['id'].toString()).delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Çözüldü işaretlendi ve kaldırıldı.")));
                _loadData();
              }
            },
            icon: const Icon(Icons.check, size: 18), label: const Text("Çözüldü"),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openStudentForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final noCtrl = TextEditingController(text: item?['no']);
    final emailCtrl = TextEditingController(text: item?['email']);
    // YENİ: Veritabanından şifreyi çekiyoruz (veya yeni kayıt için boş bırakıyoruz)
    final passCtrl = TextEditingController(text: item?['password']);

    final List<String> gradeOptions = ["Hazırlık", "1. Sınıf", "2. Sınıf", "3. Sınıf", "4. Sınıf", "Mezun"];
    String? selectedGrade = item?['grade'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? "Düzenle — Öğrenci" : "Yeni Öğrenci Ekle", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField("Ad Soyad", controller: nameCtrl),
                    const SizedBox(height: 12),
                    _buildTextField("Öğrenci No", isNumber: true, controller: noCtrl),
                    const SizedBox(height: 12),
                    _buildTextField("E-posta", controller: emailCtrl),
                    const SizedBox(height: 12),
                    // YENİ: Şifre alanı her zaman görünür, böylece Admin şifreyi değiştirebilir
                    _buildTextField("Şifre", controller: passCtrl),
                    const SizedBox(height: 12),
                    _buildDropdown("Sınıf", gradeOptions, value: gradeOptions.contains(selectedGrade) ? selectedGrade : null, onChanged: (val) => setDialogState(() => selectedGrade = val)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
                ElevatedButton(
                    onPressed: () async {
                      int docId = isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch;
                      Map<String, dynamic> newData = {
                        'id': docId,
                        'name': nameCtrl.text,
                        'no': noCtrl.text,
                        'email': emailCtrl.text,
                        'password': passCtrl.text, // YENİ: Şifreyi Firebase'e kaydediyoruz
                        'grade': selectedGrade ?? '1. Sınıf'
                      };
                      await FirebaseFirestore.instance.collection('students').doc(docId.toString()).set(newData);
                      if (context.mounted) { Navigator.pop(context); _loadData(); }
                    },
                    child: const Text("Kaydet")
                )
              ],
            );
          }
      ),
    );
  }

  void _openPriceForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final priceCtrl = TextEditingController(text: item?['price']?.replaceAll('₺', ''));

    final List<String> catOptions = ["Çay/Kahve", "İçecekler", "Atıştırmalıklar", "Yemek"];
    String? selectedCat = item?['category'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? "Düzenle — Fiyat" : "Yeni Fiyat Ekle", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDropdown("Kategori", catOptions, value: catOptions.contains(selectedCat) ? selectedCat : null, onChanged: (val) => setDialogState(() => selectedCat = val)),
                    const SizedBox(height: 12),
                    _buildTextField("Ürün Adı", controller: nameCtrl),
                    const SizedBox(height: 12),
                    _buildTextField("Fiyat", isNumber: true, controller: priceCtrl),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
                ElevatedButton(
                    onPressed: () async {
                      int docId = isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch;
                      Map<String, dynamic> newData = {
                        'id': docId,
                        'name': nameCtrl.text,
                        'price': "₺${priceCtrl.text}",
                        'category': selectedCat ?? 'Çay/Kahve'
                      };
                      await FirebaseFirestore.instance.collection('prices').doc(docId.toString()).set(newData);
                      if (context.mounted) { Navigator.pop(context); _loadData(); }
                    },
                    child: const Text("Kaydet")
                )
              ],
            );
          }
      ),
    );
  }

  void _openBuildingForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final List<String> campusOptions = ["Ataköy", "İncirli", "Basın Ekspres", "Şirinevler"];
    final List<String> locationOptions = ["Zemin Kat", "1. Kat", "2. Kat", "3. Kat", "4. Kat", "5. Kat", "Bodrum Kat", "Bahçe"];
    String? selectedCampus;
    String? selectedLocation;

    if (item != null && item['location'] != null) {
      String loc = item['location'].toString();
      if (loc.contains(',')) {
        var parts = loc.split(',');
        selectedCampus = parts[0].trim();
        selectedLocation = parts[1].trim();
      } else { selectedCampus = loc; }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? "Düzenle: Birim/Alan" : "Yeni Birim Ekle", style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Birim Adı (Örn: Hukuk Fakültesi)")),
                  const SizedBox(height: 12),
                  _buildDropdown("Kampüs Seçin", campusOptions, value: campusOptions.contains(selectedCampus) ? selectedCampus : null, onChanged: (val) => setDialogState(() => selectedCampus = val)),
                  const SizedBox(height: 12),
                  _buildDropdown("Konum/Kat Seçin", locationOptions, value: locationOptions.contains(selectedLocation) ? selectedLocation : null, onChanged: (val) => setDialogState(() => selectedLocation = val)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
              ElevatedButton(
                  onPressed: () async {
                    String finalLocation = "${selectedCampus ?? 'Belirtilmedi'}, ${selectedLocation ?? 'Belirtilmedi'}";
                    int docId = isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch;
                    Map<String, dynamic> newData = {
                      'id': docId, 'name': nameCtrl.text, 'location': finalLocation,
                      'abbr': item?['abbr'] ?? 'YENİ', 'type': item?['type'] ?? 'faculty'
                    };
                    await FirebaseFirestore.instance.collection('buildings').doc(docId.toString()).set(newData);
                    if (context.mounted) { Navigator.pop(context); _loadData(); }
                  },
                  child: const Text("Kaydet")
              )
            ],
          );
        },
      ),
    );
  }

  void _openClassroomForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final floorCtrl = TextEditingController(text: item?['floor']?.toString() ?? '');
    final capacityCtrl = TextEditingController(text: item?['capacity']?.toString() ?? '40');

    // İKÜ'nün GERÇEK BİNALARI
    List<String> campusOptions = ["Ataköy", "İncirli", "Basın Ekspres", "Şirinevler"];
    List<String> locationOptions = [
      "Ana Bina",
      "A Blok",
      "B Blok",
      "C Blok",
      "Hukuk Binası",
      "Sağlık Bilimleri Binası",
      "Hazırlık Binası"
    ];
    List<String> typeOptions = ["Derslik", "Amfi", "Laboratuvar", "Stüdyo", "Toplantı Odası"];

    String? selectedCampus;
    String? selectedLocation;
    String? selectedType = (item != null && typeOptions.contains(item['type'])) ? item['type'] : "Derslik";

    // Veritabanındaki "Kampüs, Blok" formatını ayırma
    if (item != null && item['building'] != null) {
      String buildingData = item['building'].toString();
      if (buildingData.contains(',')) {
        var parts = buildingData.split(',');
        selectedCampus = parts[0].trim();
        selectedLocation = parts[1].trim();
      } else {
        selectedCampus = buildingData;
        selectedLocation = "Ana Bina"; // ESKİ VERİLERDE BLOK YOKSA ANA BİNA VARSAY
      }
    }

    if (selectedCampus != null && !campusOptions.contains(selectedCampus)) {
      campusOptions.add(selectedCampus!);
    }
    if (selectedLocation != null && !locationOptions.contains(selectedLocation)) {
      locationOptions.add(selectedLocation!);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? "Düzenle: Derslik" : "Yeni Derslik Ekle", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField("Derslik Adı (Örn: 1A01)", controller: nameCtrl),
                    const SizedBox(height: 12),

                    _buildDropdown("Kampüs Seçin", campusOptions,
                        value: selectedCampus,
                        onChanged: (val) => setDialogState(() => selectedCampus = val)),
                    const SizedBox(height: 12),

                    _buildDropdown("Konum/Blok Seçin", locationOptions,
                        value: selectedLocation,
                        onChanged: (val) => setDialogState(() => selectedLocation = val)),
                    const SizedBox(height: 12),

                    _buildTextField("Kat (Örn: 1, 2, -1)", controller: floorCtrl, isNumber: true),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _buildTextField("Kapasite", controller: capacityCtrl, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildDropdown("Tip", typeOptions,
                              value: selectedType,
                              onChanged: (val) => setDialogState(() => selectedType = val)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: AppTheme.textMuted))),
                ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || selectedCampus == null || floorCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen Derslik adı, Kampüs ve Kat bilgilerini doldurun.")));
                        return;
                      }

                      String finalBuilding = "$selectedCampus, ${selectedLocation ?? 'Ana Bina'}";
                      int docId = isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch;

                      Map<String, dynamic> newData = {
                        'id': docId,
                        'name': nameCtrl.text,
                        'building': finalBuilding,
                        'capacity': int.tryParse(capacityCtrl.text) ?? 40,
                        'type': selectedType ?? 'Derslik',
                        'floor': int.tryParse(floorCtrl.text) ?? 1
                      };

                      await FirebaseFirestore.instance.collection('classrooms').doc(docId.toString()).set(newData);

                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    },
                    child: const Text("Kaydet")
                )
              ],
            );
          }
      ),
    );
  }

  void _openInstructorForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final deptCtrl = TextEditingController(text: item?['department']);
    final photoCtrl = TextEditingController(text: item?['imageUrl'] ?? '');

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
            const SizedBox(height: 12),
            TextField(controller: photoCtrl, decoration: const InputDecoration(labelText: "Fotoğraf Yolu (Örn: assets/instructors/hoca.jpg)", hintText: "assets/instructors/varsayilan.jpg")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
              onPressed: () async {
                int docId = isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch;
                Map<String, dynamic> newData = {
                  'id': docId, 'name': nameCtrl.text, 'department': deptCtrl.text, 'imageUrl': photoCtrl.text,
                  'title': item?['title'] ?? 'Öğretim Üyesi', 'office': item?['office'] ?? 'Bilinmiyor',
                  'filter': item?['filter'] ?? 'engineering', 'email': item?['email'] ?? 'iletisim@uni.edu.tr'
                };
                await FirebaseFirestore.instance.collection('instructors').doc(docId.toString()).set(newData);
                if (context.mounted) { Navigator.pop(context); _loadData(); }
              },
              child: const Text("Kaydet")
          )
        ],
      ),
    );
  }

  void _openEventForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
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
                int docId = isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch;
                Map<String, dynamic> newData = {
                  'id': docId, 'title': titleCtrl.text, 'date': dateCtrl.text, 'location': locCtrl.text,
                  'category': item?['category'] ?? 'Genel', 'description': item?['description'] ?? 'Detay girilmedi.'
                };
                await FirebaseFirestore.instance.collection('events').doc(docId.toString()).set(newData);
                if (context.mounted) { Navigator.pop(context); _loadData(); }
              },
              child: const Text("Kaydet")
          )
        ],
      ),
    );
  }

  void _openAnnouncementForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
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
                int docId = isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch;
                Map<String, dynamic> newData = {
                  'id': docId, 'title': titleCtrl.text, 'date': dateCtrl.text, 'content': contentCtrl.text, 'category': item?['category'] ?? 'Genel'
                };
                await FirebaseFirestore.instance.collection('announcements').doc(docId.toString()).set(newData);
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
                await FirebaseFirestore.instance.collection('settings').doc('cafeteria').set(Map<String, dynamic>.from(fullCafeteriaData));
                if (context.mounted) { Navigator.pop(context); _loadData(); }
              },
              child: const Text("Kaydet")
          )
        ],
      ),
    );
  }
}