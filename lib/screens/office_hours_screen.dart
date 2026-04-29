import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore desteği eklendi
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../data/data_service.dart';

class OfficeHoursScreen extends StatefulWidget {

  const OfficeHoursScreen({super.key});

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
    _databaseFuture = DataService.loadDatabase(); // Silinmedi, burada duruyor.
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

  // YENİ: Gerçek Firestore verisini parçalayan yardımcı fonksiyon
  List<Map<String, String>> _processRealOfficeHours(List<QueryDocumentSnapshot> docs) {
    List<Map<String, String>> finalHoursList = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String name = data['name'] ?? "";
      final String dept = data['department'] ?? "";
      final String office = data['office'] ?? "Bilinmiyor";

      // Eğer Firestore'da ofis saati varsa onu al, yoksa varsayılan listeyi kullan
      final List<dynamic> hours = (data['officeHours'] is List && (data['officeHours'] as List).isNotEmpty)
          ? data['officeHours']
          : ["Pazartesi: 10:00-12:00", "Çarşamba: 14:00-16:00"];

      for (var hourEntry in hours) {
        String hourStr = hourEntry.toString();
        String day = "Görüşme";
        String time = hourStr;

        if (hourStr.contains(':')) {
          var parts = hourStr.split(':');
          day = parts[0].trim();
          time = parts.sublist(1).join(':').trim();
        }

        finalHoursList.add({
          "name": name,
          "office": office,
          "day": day,
          "time": time,
          "dept": dept
        });
      }
    }
    return finalHoursList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Ofis Saatleri", showBack: true),
      // FutureBuilder yerine StreamBuilder gelerek veriyi "CANLI" hale getirdik
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('instructors').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Veri bulunamadı."));
            }

            // Artık yapay veri değil, Firestore'dan gelen gerçek veri işleniyor
            final allOfficeHours = _processRealOfficeHours(snapshot.data!.docs);

            final filteredHours = allOfficeHours.where((oh) {
              final String name = oh['name'] ?? "";
              final String dept = oh['dept'] ?? "";
              final String day = oh['day'] ?? "";

              final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  dept.toLowerCase().contains(_searchQuery.toLowerCase());

              // GÜNCELLENEN ESNEK FİLTRELEME: Türkçe karakterleri normalize ediyoruz
              String normalize(String text) {
                return text.toLowerCase()
                    .replaceAll('ş', 's').replaceAll('ı', 'i')
                    .replaceAll('ç', 'c').replaceAll('ğ', 'g')
                    .replaceAll('ü', 'u').replaceAll('ö', 'o');
              }

              final matchesFilter = _selectedFilter == "Tümü" ||
                  normalize(day) == normalize(_selectedFilter);

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
                        title: oh['name'] ?? "",
                        subtitle: oh['dept'] ?? "",
                        metadata: "${oh['day'] ?? ""} • ${oh['time'] ?? ""} | Ofis: ${oh['office'] ?? ""}",
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