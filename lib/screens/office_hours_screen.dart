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

  // Updated filter list with English days
  final List<String> _filters = ["All", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

  List<Map<String, String>> _processRealOfficeHours(List<QueryDocumentSnapshot> docs) {
    List<Map<String, String>> finalHoursList = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String name = data['name'] ?? "";
      final String dept = data['department'] ?? "";
      final String office = data['office'] ?? "Unknown";

      // Default values switched to English
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
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No data found."));

            final allOfficeHours = _processRealOfficeHours(snapshot.data!.docs);

            final filteredHours = allOfficeHours.where((oh) {
              final name = oh['name']!.toLowerCase();
              final dept = oh['dept']!.toLowerCase();
              final day = oh['day']!;

              final matchesSearch = name.contains(_searchQuery.toLowerCase()) || dept.contains(_searchQuery.toLowerCase());

              // Direct string comparison since data should now be in English
              final matchesFilter = _selectedFilter == "All" || day == _selectedFilter;

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
                    itemCount: _filters.length,
                    itemBuilder: (context, index) => AppFilterChip(
                      label: _filters[index],
                      active: _selectedFilter == _filters[index],
                      onTap: () => setState(() => _selectedFilter = _filters[index]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredHours.isEmpty
                      ? const Center(child: Text("No results found", style: TextStyle(color: AppTheme.textMuted)))
                      : ListView.builder(
                    itemCount: filteredHours.length,
                    itemBuilder: (context, index) {
                      final oh = filteredHours[index];
                      return InfoCard(
                        title: oh['name'] ?? "",
                        subtitle: oh['dept'] ?? "",
                        metadata: "${oh['day']} • ${oh['time']} | Office: ${oh['office']}",
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