import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/mock_data.dart';
import '../../widgets/search_bar_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    "Genel", "Binalar", "Derslikler", "Hocalar", "Etkinlikler", "Duyurular", "Yemekhane", "Fiyatlar", "Sorunlar", "Öğrenciler"
  ];

  final Map<int, TextEditingController> _searchControllers = {
    1: TextEditingController(),
    2: TextEditingController(),
    3: TextEditingController(),
    4: TextEditingController(),
    5: TextEditingController(),
    6: TextEditingController(),
    7: TextEditingController(),
    8: TextEditingController(),
    9: TextEditingController(), // Controller for Öğrenciler
  };

  // Mock prices
  final List<Map<String, String>> _mockPrices = [
    {"name": "Çay", "price": "₺3", "category": "Çay/Kahve"},
    {"name": "Türk Kahvesi", "price": "₺12", "category": "Çay/Kahve"},
    {"name": "Ayran", "price": "₺5", "category": "İçecekler"},
    {"name": "Tost", "price": "₺15", "category": "Atıştırmalıklar"},
    {"name": "Öğle Menüsü", "price": "₺35", "category": "Yemek"},
  ];

  // Mock issues reported by students
  final List<Map<String, dynamic>> _mockIssues = [
    {
      "id": 1, "category": "Altyapı Sorunu", "priority": "Yüksek",
      "subject": "Sınıfta projeksiyon çalışmıyor", "location": "MF-101",
      "description": "Bilgisayarı bağladığımızda görüntü gelmiyor, kablo kopuk olabilir.", "date": "Bugün 10:30"
    },
    {
      "id": 2, "category": "Temizlik", "priority": "Orta",
      "subject": "Lavabolarda sabun bitti", "location": "İİBF 2. Kat",
      "description": "Erkekler tuvaletindeki sıvı sabunluklar tamamen boşalmış.", "date": "Dün 14:15"
    },
    {
      "id": 3, "category": "Teknik Sorun", "priority": "Düşük",
      "subject": "Wi-Fi bağlantısı kopuyor", "location": "Kütüphane Çalışma Salonu",
      "description": "Özellikle akşam saatlerinde eduroam ağına bağlanırken sürekli kopmalar yaşanıyor.", "date": "17 Nisan 2026"
    },
  ];

  // Mock students
  final List<Map<String, String>> _mockStudents = [
    {"name": "Ahmet Yılmaz", "no": "20210001234", "email": "ahmet@uni.edu.tr", "grade": "3. Sınıf"},
    {"name": "Ayşe Demir", "no": "20220005678", "email": "ayse@uni.edu.tr", "grade": "2. Sınıf"},
    {"name": "Mehmet Kaya", "no": "20200009012", "email": "mehmet@uni.edu.tr", "grade": "4. Sınıf"},
    {"name": "Zeynep Çelik", "no": "20230003456", "email": "zeynep@uni.edu.tr", "grade": "1. Sınıf"},
    {"name": "Can Özkan", "no": "20190007890", "email": "can@uni.edu.tr", "grade": "Mezun"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    for (var controller in _searchControllers.values) {
      controller.dispose();
    }
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

  String _normalizeForSearch(String text) {
    return text.toLowerCase()
        .replaceAll('i̇', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Silmeyi Onayla"),
        content: const Text("Bu kaydı silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt silindi (Demo)")));
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
      maxLines: lines,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (val) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final sq1 = _normalizeForSearch(_searchControllers[1]!.text);
    final filteredBuildings = MockData.buildings.where((b) =>
    _normalizeForSearch(b.name).contains(sq1) || _normalizeForSearch(b.location).contains(sq1) || _normalizeForSearch(b.abbr).contains(sq1)
    ).toList();

    final sq2 = _normalizeForSearch(_searchControllers[2]!.text);
    final filteredClassrooms = MockData.classrooms.where((c) =>
    _normalizeForSearch(c.name).contains(sq2) || _normalizeForSearch(c.building).contains(sq2)
    ).toList();

    final sq3 = _normalizeForSearch(_searchControllers[3]!.text);
    final filteredInstructors = MockData.instructors.where((i) =>
    _normalizeForSearch(i.name).contains(sq3) || _normalizeForSearch(i.department).contains(sq3) || _normalizeForSearch(i.title).contains(sq3)
    ).toList();

    final sq4 = _normalizeForSearch(_searchControllers[4]!.text);
    final filteredEvents = MockData.events.where((e) =>
    _normalizeForSearch(e.title).contains(sq4) || _normalizeForSearch(e.date).contains(sq4)
    ).toList();

    final sq5 = _normalizeForSearch(_searchControllers[5]!.text);
    final filteredAnnouncements = MockData.announcements.where((a) =>
    _normalizeForSearch(a.title).contains(sq5) || _normalizeForSearch(a.date).contains(sq5)
    ).toList();

    final sq6 = _normalizeForSearch(_searchControllers[6]!.text);
    final filteredMenus = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma"].where((d) =>
        _normalizeForSearch(d).contains(sq6)
    ).toList();

    final sq7 = _normalizeForSearch(_searchControllers[7]!.text);
    final filteredPrices = _mockPrices.where((p) =>
    _normalizeForSearch(p["name"]!).contains(sq7) || _normalizeForSearch(p["category"]!).contains(sq7)
    ).toList();

    final sq8 = _normalizeForSearch(_searchControllers[8]!.text);
    final filteredIssues = _mockIssues.where((iss) =>
    _normalizeForSearch(iss["subject"]).contains(sq8) || _normalizeForSearch(iss["category"]).contains(sq8) || _normalizeForSearch(iss["location"]).contains(sq8)
    ).toList();

    final sq9 = _normalizeForSearch(_searchControllers[9]!.text);
    final filteredStudents = _mockStudents.where((s) =>
    _normalizeForSearch(s["name"]!).contains(sq9) || _normalizeForSearch(s["no"]!).contains(sq9)
    ).toList();

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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenelTab(),
          _buildManagementTab(
            title: "Binalar", count: filteredBuildings.length, searchController: _searchControllers[1]!,
            items: filteredBuildings.map((b) => _buildListItem(b.name, b.location, () => _openBuildingForm(isEdit: true))).toList(),
            onAdd: () => _openBuildingForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Derslikler", count: filteredClassrooms.length, searchController: _searchControllers[2]!,
            items: filteredClassrooms.map((c) => _buildListItem(c.name, c.building, () => _openClassroomForm(isEdit: true))).toList(),
            onAdd: () => _openClassroomForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Hocalar", count: filteredInstructors.length, searchController: _searchControllers[3]!,
            items: filteredInstructors.map((i) => _buildListItem(i.name, i.department, () => _openInstructorForm(isEdit: true))).toList(),
            onAdd: () => _openInstructorForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Etkinlikler", count: filteredEvents.length, searchController: _searchControllers[4]!,
            items: filteredEvents.map((e) => _buildListItem(e.title, e.date, () => _openEventForm(isEdit: true))).toList(),
            onAdd: () => _openEventForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Duyurular", count: filteredAnnouncements.length, searchController: _searchControllers[5]!,
            items: filteredAnnouncements.map((a) => _buildListItem(a.title, a.date, () => _openAnnouncementForm(isEdit: true))).toList(),
            onAdd: () => _openAnnouncementForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Yemekhane", count: filteredMenus.length, searchController: _searchControllers[6]!,
            items: filteredMenus.map((d) => _buildListItem("$d Menüsü", "Öğle & Akşam", () => _openMenuForm(isEdit: true))).toList(),
            onAdd: () => _openMenuForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Fiyatlar", count: filteredPrices.length, searchController: _searchControllers[7]!,
            items: filteredPrices.map((p) => _buildListItem(p["name"]!, "${p["category"]} • ${p["price"]}", () => _openPriceForm(isEdit: true))).toList(),
            onAdd: () => _openPriceForm(isEdit: false),
          ),
          _buildIssuesTab(filteredIssues, _searchControllers[8]!),

          // New Öğrenciler (Students/Users) Tab
          _buildManagementTab(
            title: "Öğrenciler", count: filteredStudents.length, searchController: _searchControllers[9]!,
            items: filteredStudents.map((s) => _buildListItem(s["name"]!, "${s["no"]} • ${s["grade"]}", () => _openStudentForm(isEdit: true))).toList(),
            onAdd: () => _openStudentForm(isEdit: false),
          ),
        ],
      ),
    );
  }

  // --- TAB BUILDERS ---

  Widget _buildGenelTab() {
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
                Expanded(child: Text("Tüm sistemler çalışıyor", style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold))),
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
            childAspectRatio: 1.25,
            children: [
              _buildStatCard(Icons.business, "Binalar", MockData.buildings.length.toString(), 1),
              _buildStatCard(Icons.meeting_room, "Derslikler", MockData.classrooms.length.toString(), 2),
              _buildStatCard(Icons.people, "Hocalar", MockData.instructors.length.toString(), 3),
              _buildStatCard(Icons.event, "Etkinlikler", MockData.events.length.toString(), 4),
              _buildStatCard(Icons.campaign, "Duyurular", MockData.announcements.length.toString(), 5),
              _buildStatCard(Icons.restaurant, "Menü", "Güncel", 6),
              _buildStatCard(Icons.attach_money, "Fiyatlar", _mockPrices.length.toString(), 7),
              _buildStatCard(Icons.report_problem, "Sorunlar", _mockIssues.length.toString(), 8),
              _buildStatCard(Icons.person, "Öğrenciler", _mockStudents.length.toString(), 9), // Students Stat Card
            ],
          ),
          const SizedBox(height: 32),

          const Text("Hızlı Yönetim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _buildQuickRow(Icons.business, "Binaları Yönet", 1),
                const Divider(height: 1),
                _buildQuickRow(Icons.meeting_room, "Derslikleri Yönet", 2),
                const Divider(height: 1),
                _buildQuickRow(Icons.people, "Hocaları Yönet", 3),
                const Divider(height: 1),
                _buildQuickRow(Icons.report_problem, "Gelen Sorunları İncele", 8),
                const Divider(height: 1),
                _buildQuickRow(Icons.person, "Öğrencileri Yönet", 9), // Students Quick Row
              ],
            ),
          )
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
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
              ],
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRow(IconData icon, String label, int tabIndex) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textMuted),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _switchTab(tabIndex),
    );
  }

  Widget _buildManagementTab({
    required String title,
    required int count,
    required List<Widget> items,
    required VoidCallback onAdd,
    required TextEditingController searchController,
  }) {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AppSearchBar(
            controller: searchController,
            placeholder: "Ara...",
            onChanged: (val) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
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

  Widget _buildListItem(String title, String subtitle, VoidCallback onEdit) {
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
        IconButton(icon: const Icon(Icons.delete, color: AppTheme.destructiveColor), onPressed: _showDeleteDialog),
      ],
    );
  }

  Widget _buildIssuesTab(List<Map<String, dynamic>> issues, TextEditingController searchController) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Gelen Sorunlar (${issues.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AppSearchBar(
            controller: searchController,
            placeholder: "Konu veya konum ara...",
            onChanged: (val) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: issues.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final issue = issues[index];
              Color priorityColor;
              if (issue["priority"] == "Yüksek") priorityColor = AppTheme.destructiveColor;
              else if (issue["priority"] == "Orta") priorityColor = AppTheme.warningColor;
              else priorityColor = AppTheme.successColor;

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
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text("${issue["category"]} • ${issue["location"]}\n${issue["date"]}", style: const TextStyle(color: AppTheme.textMuted)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye, color: AppTheme.primaryLight),
                      tooltip: "İncele",
                      onPressed: () => _openIssueDetailsDialog(issue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.destructiveColor),
                      tooltip: "Sil",
                      onPressed: _showDeleteDialog,
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () => _openIssueDetailsDialog(issue),
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
              Text("Öncelik: ${issue["priority"]}", style: const TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text("Konum: ${issue["location"]}", style: const TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text("Tarih: ${issue["date"]}", style: const TextStyle(color: AppTheme.textMuted)),
              const Divider(height: 24),
              const Text("Açıklama:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(issue["description"], style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat", style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sorun çözüldü olarak işaretlendi!")));
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text("Çözüldü İşaretle", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  // --- FORM MODALS ---

  void _openBuildingForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Bina" : "Yeni Bina Ekle",
        fields: [
          _buildTextField("Bina Adı"), _buildTextField("Kısaltma"),
          _buildTextField("Kat Sayısı", isNumber: true), _buildTextField("Oda Sayısı", isNumber: true),
          _buildDropdown("Tür", ["Akademik", "İdari", "Sosyal"]), _buildTextField("Konum"),
        ]
    );
  }

  void _openClassroomForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Derslik" : "Yeni Derslik Ekle",
        fields: [
          _buildTextField("Derslik Adı"), _buildDropdown("Bina", ["Mühendislik Fakültesi", "İİBF", "Fen Edebiyat"]),
          _buildTextField("Kapasite", isNumber: true), _buildDropdown("Tür", ["Derslik", "Amfi", "Laboratuvar", "Seminer Salonu"]),
          _buildTextField("Kat", isNumber: true),
        ]
    );
  }

  void _openInstructorForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Hoca" : "Yeni Hoca Ekle",
        fields: [
          _buildTextField("Ad Soyad"), _buildDropdown("Unvan", ["Profesör", "Doçent", "Dr. Öğretim Üyesi", "Arş. Gör."]),
          _buildTextField("Bölüm"), _buildTextField("Ofis"),
        ]
    );
  }

  void _openEventForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Etkinlik" : "Yeni Etkinlik Ekle",
        fields: [
          _buildTextField("Etkinlik Adı"), _buildTextField("Tarih"), _buildTextField("Saat"),
          _buildTextField("Konum"), _buildDropdown("Kategori", ["Akademik", "Kültürel", "Spor", "Sosyal"]),
        ]
    );
  }

  void _openAnnouncementForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Duyuru" : "Yeni Duyuru Ekle",
        fields: [
          _buildTextField("Başlık"), _buildDropdown("Kategori", ["Genel", "Akademik", "İdari", "Burs"]),
          _buildTextField("Tarih"), _buildTextField("İçerik", lines: 4),
        ]
    );
  }

  void _openMenuForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Menüyü Düzenle" : "Menü Ekle",
        fields: [
          _buildDropdown("Gün", ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]),
          _buildDropdown("Öğün", ["Kahvaltı", "Öğle", "Akşam"]), _buildTextField("Yemekler (Virgül ile ayırın)", lines: 3),
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

  // New modal for managing students/users
  void _openStudentForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Öğrenci" : "Yeni Öğrenci Ekle",
        fields: [
          _buildTextField("Ad Soyad"),
          _buildTextField("Öğrenci No", isNumber: true),
          _buildTextField("E-posta"),
          _buildTextField("Şifre", isPassword: true), // Masks the text for password fields
          _buildDropdown("Sınıf", ["Hazırlık", "1. Sınıf", "2. Sınıf", "3. Sınıf", "4. Sınıf", "Mezun"]),
        ]
    );
  }
}