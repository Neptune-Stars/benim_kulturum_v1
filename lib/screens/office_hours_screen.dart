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
  String _selectedFilter = "All";

  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _filters = ["All", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }


  List<Map<String, String>> _generateDynamicOfficeHours(List<dynamic> instructors) {
    List<Map<String, String>> generatedList = [];
    final days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

    for (int i = 0; i < instructors.length; i++) {
      var instructor = instructors[i];
      String day1 = days[i % 5];
      String day2 = days[(i + 2) % 5];

      generatedList.add({
        "name": instructor['name']?.toString() ?? "",
        "office": instructor['office']?.toString() ?? "Unknown",
        "day": day1,
        "time": "10:00-12:00",
        "dept": instructor['department']?.toString() ?? ""
      });

      generatedList.add({
        "name": instructor['name']?.toString() ?? "",
        "office": instructor['office']?.toString() ?? "Unknown",
        "day": day2,
        "time": "14:00-16:00",
        "dept": instructor['department']?.toString() ?? ""
      });
    }
    return generatedList;
  }

  List<Map<String, String>> _processRealOfficeHours(List<QueryDocumentSnapshot> docs) {
    List<Map<String, String>> finalHoursList = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String name = data['name'] ?? "";
      final String dept = data['department'] ?? "";
      final String office = data['office'] ?? "Unknown";

      final List<dynamic> hours = (data['officeHours'] is List && (data['officeHours'] as List).isNotEmpty)
          ? data['officeHours']
          : ["Monday: 10:00-12:00", "Wednesday: 14:00-16:00"];

      for (var hourEntry in hours) {
        String hourStr = hourEntry.toString();
        String day = "Meeting";
        String time = hourStr;

        if (hourStr.contains(':')) {
          var parts = hourStr.split(':');
          day = parts[0].trim();

          // Translating basic Turkish days from DB if present
          if (day == "Pazartesi") day = "Monday";
          if (day == "Salı") day = "Tuesday";
          if (day == "Çarşamba") day = "Wednesday";
          if (day == "Perşembe") day = "Thursday";
          if (day == "Cuma") day = "Friday";

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
      appBar: const CustomAppBar(title: "Office Hours", showBack: true),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('instructors').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Data not found."));
            }

            final allOfficeHours = _processRealOfficeHours(snapshot.data!.docs);

            final filteredHours = allOfficeHours.where((oh) {
              final String name = oh['name'] ?? "";
              final String dept = oh['dept'] ?? "";
              final String day = oh['day'] ?? "";

              final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  dept.toLowerCase().contains(_searchQuery.toLowerCase());

              String normalize(String text) {
                return text.toLowerCase()
                    .replaceAll('ş', 's').replaceAll('ı', 'i')
                    .replaceAll('ç', 'c').replaceAll('ğ', 'g')
                    .replaceAll('ü', 'u').replaceAll('ö', 'o');
              }

              final matchesFilter = _selectedFilter == "All" ||
                  normalize(day) == normalize(_selectedFilter);

              return matchesSearch && matchesFilter;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppSearchBar(
                    placeholder: "Search instructor or department...",
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
                      ? const Center(child: Text("No results found", style: TextStyle(color: AppTheme.textMuted)))
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredHours.length,
                    itemBuilder: (context, index) {
                      final oh = filteredHours[index];
                      return InfoCard(
                        title: oh['name'] ?? "",
                        subtitle: oh['dept'] ?? "",
                        metadata: "${oh['day'] ?? ""} • ${oh['time'] ?? ""} | Office: ${oh['office'] ?? ""}",
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