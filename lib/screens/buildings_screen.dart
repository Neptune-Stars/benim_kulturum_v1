import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart';
import 'building_detail_screen.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({Key? key}) : super(key: key);

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _filters = [
    "Tümü",
    "Fakülteler",
    "İdari Birimler",
    "Sosyal Alanlar",
    "Yeme-İçme",
    "Çalışma Alanları",
  ];

  final List<Map<String, String>> _campuses = [
    {
      "title": "Ataköy",
      "address": "İstanbul Kültür Üniversitesi Ataköy Yerleşkesi, E5 Karayolu üzeri Bakırköy 34158 İstanbul",
    },
    {
      "title": "Şirinevler",
      "address": "İstanbul Kültür Üniversitesi Şirinevler Yerleşkesi, E5 Karayolu Üzeri No:22 Bahçelievler 34191 İstanbul",
    },
    {
      "title": "İncirli",
      "address": "İstanbul Kültür Üniversitesi İncirli Yerleşkesi, Yolbaşı Sokak, 34147 Bakırköy İstanbul",
    },
    {
      "title": "Basın Ekspres",
      "address": "İstanbul Kültür Üniversitesi Basın Ekspres Yerleşkesi, Halkalı Merkez Mahallesi Basın Ekspres Caddesi No:11 34303 Küçükçekmece İstanbul",
    },
  ];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  String _normalizeType(String rawType) {
    switch (rawType.toLowerCase()) {
      case "academic":
      case "faculty":
        return "faculty";
      case "admin":
      case "administrative":
      case "admin_unit":
        return "admin";
      case "social":
        return "social";
      case "food":
      case "cafeteria":
      case "canteen":
        return "food";
      case "study":
      case "library":
      case "workspace":
        return "study";
      default:
        return "unknown";
    }
  }

  String _getTypeLabel(String rawType) {
    final type = _normalizeType(rawType);
    switch (type) {
      case "faculty": return "Fakülte";
      case "admin": return "İdari";
      case "social": return "Sosyal";
      case "food": return "Yeme-İçme";
      case "study": return "Çalışma";
      default: return "Genel";
    }
  }

  bool _matchesFilter(String selectedFilter, String rawType) {
    final type = _normalizeType(rawType);
    if (selectedFilter == "Tümü") return true;
    if (selectedFilter == "Fakülteler" && type == "faculty") return true;
    if (selectedFilter == "İdari Birimler" && type == "admin") return true;
    if (selectedFilter == "Sosyal Alanlar" && type == "social") return true;
    if (selectedFilter == "Yeme-İçme" && type == "food") return true;
    if (selectedFilter == "Çalışma Alanları" && type == "study") return true;
    return false;
  }

  Future<void> _openCampusMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedAddress?q=$encodedAddress");

    try {
      final bool opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harita açılamadı.")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Harita açılırken hata oluştu: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Scaffold(
      appBar: const CustomAppBar(title: "Kampüs Rehberi", showBack: true),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!['buildings'] == null) {
              return const Center(child: Text("Bina verisi bulunamadı."));
            }

            final allBuildings = snapshot.data!['buildings'] as List<dynamic>? ?? [];

            final filteredBuildings = allBuildings.where((b) {
              final name = b['name']?.toString() ?? "";
              final abbr = b['abbr']?.toString() ?? "";
              final loc = b['location']?.toString() ?? "";
              final type = b['type']?.toString() ?? "";

              final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  abbr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  loc.toLowerCase().contains(_searchQuery.toLowerCase());

              final matchesFilter = _matchesFilter(_selectedFilter, type);

              return matchesSearch && matchesFilter;
            }).toList();

            // Sayfanın TAMAMI artık tek bir kaydırılabilir yapı içinde (CustomScrollView)
            return CustomScrollView(
              slivers: [
                // 1. Kısım: Arama Çubuğu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AppSearchBar(
                      placeholder: "Birim, fakülte veya alan ara...",
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ),

                // 2. Kısım: Filtre Butonları
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        return AppFilterChip(
                          label: filter,
                          active: _selectedFilter == filter,
                          onTap: () => setState(() => _selectedFilter = filter),
                        );
                      },
                    ),
                  ),
                ),

                // 3. Kısım: Harita Kartı (Binalarla Birlikte Kayacak)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.map_outlined, color: AppTheme.primaryColor),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "İstanbul’daki Kampüsler",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("Yerleşkelerden birine dokunarak haritada aç.", style: TextStyle(fontSize: 13, color: mutedColor)),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _campuses.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4,
                            ),
                            itemBuilder: (context, index) {
                              final campus = _campuses[index];
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openCampusMap(campus["address"]!),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Theme.of(context).dividerColor),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primaryColor),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(campus["title"]!, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Kısım: Binaların Listesi (Eğer Boşsa)
                if (filteredBuildings.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          "Seçtiğin filtrelere uygun kayıt bulunamadı.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                // 5. Kısım: Binaların Listesi (Doluysa)
                if (filteredBuildings.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final b = filteredBuildings[index];
                          // Özel bir meta data oluştur. (Örn: Sadece 1 katlı kafeler için kat bilgisi yazmasın)
                          String metadata = "";
                          if (b['type'] == "faculty" || b['type'] == "admin") {
                            metadata = "${b['floors'] ?? 1} kat • ${b['rooms'] ?? 10} alan";
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0), // Kartlar arası boşluk
                            child: InfoCard(
                              title: b['name']?.toString() ?? "",
                              subtitle: b['location']?.toString() ?? "",
                              metadata: metadata,
                              badge: AppBadge(label: _getTypeLabel(b['type']?.toString() ?? "")),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BuildingDetailScreen(buildingData: b)),
                              ),
                            ),
                          );
                        },
                        childCount: filteredBuildings.length,
                      ),
                    ),
                  ),
              ],
            );
          }
      ),
    );
  }
}