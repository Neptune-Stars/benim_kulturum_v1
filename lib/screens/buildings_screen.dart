import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart'; // MOCK DATA YERİNE JSON SERVİSİ
import 'building_detail_screen.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({Key? key}) : super(key: key);

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";
  late Future<Map<String, dynamic>> _databaseFuture; // JSON Future

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
      "address":
      "İstanbul Kültür Üniversitesi Ataköy Yerleşkesi, E5 Karayolu üzeri Bakırköy 34158 İstanbul",
    },
    {
      "title": "Şirinevler",
      "address":
      "İstanbul Kültür Üniversitesi Şirinevler Yerleşkesi, E5 Karayolu Üzeri No:22 Bahçelievler 34191 İstanbul",
    },
    {
      "title": "İncirli",
      "address":
      "İstanbul Kültür Üniversitesi İncirli Yerleşkesi, Yolbaşı Sokak, 34147 Bakırköy İstanbul",
    },
    {
      "title": "Basın Ekspres",
      "address":
      "İstanbul Kültür Üniversitesi Basın Ekspres Yerleşkesi, Halkalı Merkez Mahallesi Basın Ekspres Caddesi No:11 34303 Küçükçekmece İstanbul",
    },
  ];

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
      case "faculty":
        return "Fakülte";
      case "admin":
        return "İdari";
      case "social":
        return "Sosyal";
      case "food":
        return "Yeme-İçme";
      case "study":
        return "Çalışma";
      default:
        return "Genel";
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

    final Uri uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$encodedAddress",
    );

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Harita açılamadı."),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Harita açılırken hata oluştu: $e"),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final filteredBuildings = MockData.buildings.where((b) {
      final matchesSearch =
          b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.abbr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.location.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _matchesFilter(_selectedFilter, b.type);

      return matchesSearch && matchesFilter;
    }).toList();

    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextMuted
        : AppTheme.textMuted;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Kampüs Rehberi",
        showBack: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppSearchBar(
              placeholder: "Birim, fakülte veya alan ara...",
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          SizedBox(
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryLight.withOpacity(0.25),
                ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Yerleşkelerden birine dokunarak haritada aç.",
                    style: TextStyle(
                      fontSize: 13,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _campuses.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.4,
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
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  campus["title"]!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
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
          const SizedBox(height: 16),
          Expanded(
            child: filteredBuildings.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Seçtiğin filtrelere uygun kayıt bulunamadı.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 16,
                  ),
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredBuildings.length,
              itemBuilder: (context, index) {
                final b = filteredBuildings[index];

                return InfoCard(
                  title: b.name,
                  subtitle: b.location,
                  metadata: "${b.floors} kat • ${b.rooms} alan",
                  badge: AppBadge(label: _getTypeLabel(b.type)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuildingDetailScreen(building: b),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text("Kampüs haritasını görüntüle", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Haritayı Aç", style: TextStyle(color: AppTheme.primaryColor)),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredBuildings.length,
                  itemBuilder: (context, index) {
                    final b = filteredBuildings[index];
                    return InfoCard(
                      title: b['name'] ?? "",
                      subtitle: b['location'] ?? "",
                      badge: AppBadge(label: b['abbr'] ?? ""),
                      onTap: () => Navigator.push(
                          context,
                          // Artık modele değil, Map objesine (b) gönderiyoruz
                          MaterialPageRoute(builder: (_) => BuildingDetailScreen(buildingData: b))
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}