import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../data/data_service.dart';

class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen({Key? key}) : super(key: key);

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  late Future<Map<String, dynamic>> _databaseFuture;

  String _searchQuery = "";

  // Aktif Filtreler
  String _selectedCampus = "Tümü";
  String _selectedType = "Tümü";
  String _selectedFloor = "Tümü";

  // Filtre Seçenekleri
  final List<String> _campusOptions = ["Tümü", "Ataköy", "Şirinevler", "İncirli", "Basın Ekspres"];
  final List<String> _typeOptions = ["Tümü", "Derslik", "Amfi", "Laboratuvar", "Stüdyo", "Toplantı Odası"];
  final List<String> _floorOptions = ["Tümü", "-2", "-1", "0", "1", "2", "3", "4"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  String _normalize(String text) {
    return text.toLowerCase()
        .replaceAll('i̇', 'i').replaceAll('ı', 'i').replaceAll('ğ', 'g')
        .replaceAll('ü', 'u').replaceAll('ş', 's').replaceAll('ö', 'o').replaceAll('ç', 'c');
  }

  // Filtrelerin seçildiği alttan açılan menü
  void _openFilterSheet() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setSheetState) {
                final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Filtrele", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCampus = "Tümü";
                                _selectedType = "Tümü";
                                _selectedFloor = "Tümü";
                              });
                              setSheetState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text("Temizle", style: TextStyle(color: AppTheme.primaryColor)),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildFilterDropdown("Kampüs", _campusOptions, _selectedCampus, (val) {
                        setState(() => _selectedCampus = val!);
                        setSheetState(() {});
                      }),
                      const SizedBox(height: 16),

                      _buildFilterDropdown("Sınıf Tipi", _typeOptions, _selectedType, (val) {
                        setState(() => _selectedType = val!);
                        setSheetState(() {});
                      }),
                      const SizedBox(height: 16),

                      _buildFilterDropdown("Kat", _floorOptions, _selectedFloor, (val) {
                        setState(() => _selectedFloor = val!);
                        setSheetState(() {});
                      }),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Uygula", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  Widget _buildFilterDropdown(String label, List<String> options, String currentValue, Function(String?) onChanged) {
    final borderColor = Theme.of(context).dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentValue,
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final borderColor = Theme.of(context).dividerColor;

    // Aktif filtreleri listele (Chip olarak göstermek için)
    List<Widget> activeFilterChips = [];

    if (_selectedCampus != "Tümü") {
      activeFilterChips.add(_buildActiveFilterChip(_selectedCampus, () => setState(() => _selectedCampus = "Tümü")));
    }
    if (_selectedType != "Tümü") {
      activeFilterChips.add(_buildActiveFilterChip(_selectedType, () => setState(() => _selectedType = "Tümü")));
    }
    if (_selectedFloor != "Tümü") {
      activeFilterChips.add(_buildActiveFilterChip("Kat: $_selectedFloor", () => setState(() => _selectedFloor = "Tümü")));
    }

    return Scaffold(
      appBar: const CustomAppBar(title: "Derslikler ve Amfiler", showBack: true),
      body: Column(
        children: [
          // Arama Çubuğu ve Filtre Butonu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    placeholder: "Derslik kodu veya adı ara...",
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _openFilterSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: activeFilterChips.isNotEmpty ? AppTheme.primaryColor : (isDark ? Colors.white.withOpacity(0.05) : AppTheme.primaryLight.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: activeFilterChips.isNotEmpty ? AppTheme.primaryColor : borderColor),
                    ),
                    child: Icon(
                        Icons.tune,
                        color: activeFilterChips.isNotEmpty ? Colors.white : AppTheme.primaryColor
                    ),
                  ),
                )
              ],
            ),
          ),

          // Aktif Filtre Chipleri
          if (activeFilterChips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeFilterChips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => activeFilterChips[index],
                ),
              ),
            ),

          if (activeFilterChips.isNotEmpty) const SizedBox(height: 8),

          // Liste Görünümü
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
                future: _databaseFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allClassrooms = snapshot.data?['classrooms'] as List<dynamic>? ?? [];

                  // Verileri Filtreleme Mantığı
                  var filtered = allClassrooms.where((c) {
                    bool matchesSearch = _searchQuery.isEmpty ||
                        _normalize(c['name']?.toString() ?? '').contains(_normalize(_searchQuery)) ||
                        _normalize(c['building']?.toString() ?? '').contains(_normalize(_searchQuery));

                    bool matchesCampus = _selectedCampus == "Tümü" || (c['building']?.toString() ?? '').contains(_selectedCampus);
                    bool matchesType = _selectedType == "Tümü" || c['type'] == _selectedType;
                    bool matchesFloor = _selectedFloor == "Tümü" || c['floor'].toString() == _selectedFloor;

                    return matchesSearch && matchesCampus && matchesType && matchesFloor;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text("Filtrelere uygun derslik bulunamadı.", style: TextStyle(color: AppTheme.textMuted)),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      return _buildClassroomCard(c, textColor, borderColor, isDark);
                    },
                  );
                }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
      deleteIcon: const Icon(Icons.close, size: 16, color: AppTheme.primaryColor),
      onDeleted: onRemove,
      backgroundColor: AppTheme.primaryLight.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildClassroomCard(Map<dynamic, dynamic> data, Color textColor, Color borderColor, bool isDark) {
    Color typeColor;
    String type = data['type']?.toString() ?? 'Derslik';

    switch(type) {
      case 'Amfi': typeColor = AppTheme.warningColor; break;
      case 'Laboratuvar': typeColor = AppTheme.secondaryColor; break;
      case 'Stüdyo': typeColor = Colors.purple; break;
      case 'Toplantı Odası': typeColor = Colors.teal; break;
      default: typeColor = AppTheme.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.meeting_room, color: typeColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['name']?.toString() ?? 'İsimsiz',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(type, style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                    data['building']?.toString() ?? '',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoBadge(Icons.layers, "${data['floor']}. Kat"),
                    const SizedBox(width: 12),
                    _buildInfoBadge(Icons.people, "${data['capacity']} Kişi"),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}