import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../data/data_service.dart';

class OfficeHoursScreen extends StatefulWidget {
  const OfficeHoursScreen({Key? key}) : super(key: key);

  @override
  State<OfficeHoursScreen> createState() => _OfficeHoursScreenState();
}

class _OfficeHoursScreenState extends State<OfficeHoursScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _filters = ["Tümü", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  List<Map<String, String>> _generateDynamicOfficeHours(List<dynamic> instructors) {
    List<Map<String, String>> generatedList = [];
    final days = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma"];

    for (int i = 0; i < instructors.length; i++) {
      var instructor = instructors[i];
      String day1 = days[i % 5];
      String day2 = days[(i + 2) % 5];

      generatedList.add({
        "name": instructor['name']?.toString() ?? "",
        "office": instructor['office']?.toString() ?? "Bilinmiyor",
        "day": day1,
        "time": "10:00-12:00",
        "dept": instructor['department']?.toString() ?? ""
      });

      generatedList.add({
        "name": instructor['name']?.toString() ?? "",
        "office": instructor['office']?.toString() ?? "Bilinmiyor",
        "day": day2,
        "time": "14:00-16:00",
        "dept": instructor['department']?.toString() ?? ""
      });
    }
    return generatedList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Ofis Saatleri", showBack: true),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Veri bulunamadı."));
            }

            final allInstructors = snapshot.data!['instructors'] as List<dynamic>? ?? [];
            final allOfficeHours = _generateDynamicOfficeHours(allInstructors);

            final filteredHours = allOfficeHours.where((oh) {
              final matchesSearch = oh['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  oh['dept']!.toLowerCase().contains(_searchQuery.toLowerCase());

              final matchesFilter = _selectedFilter == "Tümü" || oh['day'] == _selectedFilter;

              return matchesSearch && matchesFilter;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppSearchBar(
                    placeholder: "Hoca veya bölüm ara...",
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
                Expanded(
                  child: filteredHours.isEmpty
                      ? const Center(child: Text("Sonuç bulunamadı", style: TextStyle(color: AppTheme.textMuted)))
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredHours.length,
                    itemBuilder: (context, index) {
                      final oh = filteredHours[index];
                      return InfoCard(
                        title: oh['name']!,
                        subtitle: oh['dept']!,
                        metadata: "${oh['day']} • ${oh['time']} | Ofis: ${oh['office']}",
                        showChevron: false,
                      );
                    },
                  ),
                ),
              ],
            );
          }
      ),
    );
  }
}