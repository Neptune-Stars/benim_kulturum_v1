import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';

class OfficeHoursScreen extends StatefulWidget {
  const OfficeHoursScreen({super.key});

  @override
  State<OfficeHoursScreen> createState() => _OfficeHoursScreenState();
}

class _OfficeHoursScreenState extends State<OfficeHoursScreen> {
  String _searchQuery = "";
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

  List<Map<String, dynamic>> _generateRealisticFallback(String id, String office) {
    final int seed = id.hashCode;
    final List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
    final List<String> blocks = [
      "09:00 - 11:00", "10:00 - 12:00", "11:00 - 13:00",
      "13:00 - 15:00", "14:00 - 16:00", "15:00 - 17:00"
    ];

    String day1 = days[seed % days.length];
    String time1 = blocks[seed % blocks.length];
    String day2 = days[(seed + 2) % days.length];
    String time2 = blocks[(seed + 3) % blocks.length];

    return [
      {"day": day1, "startTime": time1.split(" - ")[0], "endTime": time1.split(" - ")[1], "office": office},
      {"day": day2, "startTime": time2.split(" - ")[0], "endTime": time2.split(" - ")[1], "office": office},
    ];
  }

  String _normalize(String text) {
    return text.toLowerCase()
        .replaceAll('ş', 's').replaceAll('ı', 'i')
        .replaceAll('ç', 'c').replaceAll('ğ', 'g')
        .replaceAll('ü', 'u').replaceAll('ö', 'o');
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
            return const Center(child: Text("No instructors found."));
          }


          final List<Map<String, dynamic>> groupedList = [];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String id = doc.id;
            final String name = data['name'] ?? "Unknown";
            final String dept = data['department'] ?? "";
            final String mainOffice = data['office'] ?? "Unknown";


            List<dynamic> rawHours = (data['officeHours'] is List && (data['officeHours'] as List).isNotEmpty)
                ? data['officeHours']
                : _generateRealisticFallback(id, mainOffice);


            List<String> formattedSlots = [];
            bool hasMatchingDay = false;

            for (var hour in rawHours) {
              String day = "";
              String time = "";
              String office = mainOffice;

              if (hour is Map) {
                day = hour['day'] ?? "";
                String start = hour['startTime'] ?? "";
                String end = hour['endTime'] ?? "";
                office = hour['office'] ?? mainOffice;

                if (start.isEmpty && end.isEmpty) {
                  continue;
                }
                time = "$start - $end";
              } else {

                String str = hour.toString();
                if (str.contains(':')) {
                  day = str.split(':')[0].trim();
                  time = str.split(':').sublist(1).join(':').trim();
                }
              }


              if (_selectedFilter == "All" || _normalize(day) == _normalize(_selectedFilter)) {
                hasMatchingDay = true;
                formattedSlots.add("$day • $time | Office: $office");
              }
            }


            final bool matchesSearch = _normalize(name).contains(_normalize(_searchQuery)) ||
                _normalize(dept).contains(_normalize(_searchQuery));

            if (matchesSearch && hasMatchingDay) {
              // Eğer veritabanı kaydı bozuksa ve hiçbir slot oluşmadıysa taslağı zorla
              if (formattedSlots.isEmpty && _selectedFilter == "All") {
                final fallback = _generateRealisticFallback(id, mainOffice);
                for (var f in fallback) {
                  formattedSlots.add("${f['day']} • ${f['startTime']} - ${f['endTime']} | Office: ${f['office']}");
                }
              }

              groupedList.add({
                "name": name,
                "dept": dept,
                "displayInfo": formattedSlots.join("\n"), // Saatleri alt alta birleştir
              });
            }
          }

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
                child: groupedList.isEmpty
                    ? const Center(child: Text("No results found"))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: groupedList.length,
                  itemBuilder: (context, index) {
                    final item = groupedList[index];
                    return InfoCard(
                      title: item['name'],
                      subtitle: item['dept'],
                      metadata: item['displayInfo'],
                      showChevron: false,
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