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
    "Genel", "Binalar", "Derslikler", "Hocalar", "Etkinlikler", "Duyurular", "Yemekhane"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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

  Widget _buildTextField(String label, {bool isNumber = false, int lines = 1}) {
    return TextField(
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: lines,
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
            title: "Binalar",
            count: MockData.buildings.length,
            items: MockData.buildings.map((b) => _buildListItem(b.name, b.location, () => _openBuildingForm(isEdit: true))).toList(),
            onAdd: () => _openBuildingForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Derslikler",
            count: MockData.classrooms.length,
            items: MockData.classrooms.map((c) => _buildListItem(c.name, c.building, () => _openClassroomForm(isEdit: true))).toList(),
            onAdd: () => _openClassroomForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Hocalar",
            count: MockData.instructors.length,
            items: MockData.instructors.map((i) => _buildListItem(i.name, i.department, () => _openInstructorForm(isEdit: true))).toList(),
            onAdd: () => _openInstructorForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Etkinlikler",
            count: MockData.events.length,
            items: MockData.events.map((e) => _buildListItem(e.title, e.date, () => _openEventForm(isEdit: true))).toList(),
            onAdd: () => _openEventForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Duyurular",
            count: MockData.announcements.length,
            items: MockData.announcements.map((a) => _buildListItem(a.title, a.date, () => _openAnnouncementForm(isEdit: true))).toList(),
            onAdd: () => _openAnnouncementForm(isEdit: false),
          ),
          _buildManagementTab(
            title: "Yemekhane",
            count: 5, // Pazartesi-Cuma
            items: ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma"].map((d) => _buildListItem("$d Menüsü", "Öğle & Akşam", () => _openMenuForm(isEdit: true))).toList(),
            onAdd: () => _openMenuForm(isEdit: false),
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
          // Status Card
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

          // Stat Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(Icons.business, "Binalar", MockData.buildings.length.toString(), 1),
              _buildStatCard(Icons.meeting_room, "Derslikler", MockData.classrooms.length.toString(), 2),
              _buildStatCard(Icons.people, "Hocalar", MockData.instructors.length.toString(), 3),
              _buildStatCard(Icons.event, "Etkinlikler", MockData.events.length.toString(), 4),
              _buildStatCard(Icons.campaign, "Duyurular", MockData.announcements.length.toString(), 5),
              _buildStatCard(Icons.restaurant, "Menü", "Güncel", 6),
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: AppSearchBar(placeholder: "Ara..."),
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

  // --- FORM MODALS ---

  void _openBuildingForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Bina" : "Yeni Bina Ekle",
        fields: [
          _buildTextField("Bina Adı"),
          _buildTextField("Kısaltma"),
          _buildTextField("Kat Sayısı", isNumber: true),
          _buildTextField("Oda Sayısı", isNumber: true),
          _buildDropdown("Tür", ["Akademik", "İdari", "Sosyal"]),
          _buildTextField("Konum"),
        ]
    );
  }

  void _openClassroomForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Derslik" : "Yeni Derslik Ekle",
        fields: [
          _buildTextField("Derslik Adı"),
          _buildDropdown("Bina", ["Mühendislik Fakültesi", "İİBF", "Fen Edebiyat"]),
          _buildTextField("Kapasite", isNumber: true),
          _buildDropdown("Tür", ["Derslik", "Amfi", "Laboratuvar", "Seminer Salonu"]),
          _buildTextField("Kat", isNumber: true),
        ]
    );
  }

  void _openInstructorForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Hoca" : "Yeni Hoca Ekle",
        fields: [
          _buildTextField("Ad Soyad"),
          _buildDropdown("Unvan", ["Profesör", "Doçent", "Dr. Öğretim Üyesi", "Arş. Gör."]),
          _buildTextField("Bölüm"),
          _buildTextField("Ofis"),
        ]
    );
  }

  void _openEventForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Etkinlik" : "Yeni Etkinlik Ekle",
        fields: [
          _buildTextField("Etkinlik Adı"),
          _buildTextField("Tarih"),
          _buildTextField("Saat"),
          _buildTextField("Konum"),
          _buildDropdown("Kategori", ["Akademik", "Kültürel", "Spor", "Sosyal"]),
        ]
    );
  }

  void _openAnnouncementForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Düzenle — Duyuru" : "Yeni Duyuru Ekle",
        fields: [
          _buildTextField("Başlık"),
          _buildDropdown("Kategori", ["Genel", "Akademik", "İdari", "Burs"]),
          _buildTextField("Tarih"),
          _buildTextField("İçerik", lines: 4),
        ]
    );
  }

  void _openMenuForm({required bool isEdit}) {
    _showFormDialog(
        title: isEdit ? "Menüyü Düzenle" : "Menü Ekle",
        fields: [
          _buildDropdown("Gün", ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]),
          _buildDropdown("Öğün", ["Kahvaltı", "Öğle", "Akşam"]),
          _buildTextField("Yemekler (Virgül ile ayırın)", lines: 3),
        ]
    );
  }
}