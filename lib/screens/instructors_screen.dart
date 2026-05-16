import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import 'instructor_detail_screen.dart';

class InstructorsScreen extends StatefulWidget {
  const InstructorsScreen({Key? key}) : super(key: key);

  @override
  State<InstructorsScreen> createState() => _InstructorsScreenState();
}

class _InstructorsScreenState extends State<InstructorsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "All";

  final List<String> _filters = [
    "All", "Engineering", "Economics", "Science", "Law",
    "Architecture", "Psychology", "Literature"
  ];


  String _cleanOfficeHourTime(String value) {
    final withoutPipeOffice = value.split('|').first.trim();
    final cleaned = withoutPipeOffice
        .replaceAll(RegExp(r'\s*Office\s*:.*$', caseSensitive: false), '')
        .trim();

    return cleaned.isNotEmpty ? cleaned : "-";
  }

  String _getDynamicOfficeHoursText(List<dynamic>? existingHours) {
    if (existingHours != null && existingHours.isNotEmpty) {
      final first = existingHours.first;

      if (first is Map) {
        final day = first['day']?.toString() ?? '';
        final start = first['startTime']?.toString() ?? '';
        final end = first['endTime']?.toString() ?? '';

        if (day.isNotEmpty && start.isNotEmpty && end.isNotEmpty) {
          return "$day • ${_cleanOfficeHourTime('$start - $end')}";
        }
      }

      return _cleanOfficeHourTime(first.toString());
    }

    return "Office hours not added";
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
      appBar: const CustomAppBar(title: "Instructors", showBack: true),
      body: Column(
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('instructors').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Instructor data not found."));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toString() ?? "";
                  final dept = data['department']?.toString() ?? "";
                  final filterValue = data['filter']?.toString() ?? "";

                  final matchesSearch = _normalize(name).contains(_normalize(_searchQuery)) ||
                      _normalize(dept).contains(_normalize(_searchQuery));

                  bool matchesFilter = _selectedFilter == "All" ||
                      _normalize(filterValue) == _normalize(_selectedFilter);

                  return matchesSearch && matchesFilter;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final Map<String, dynamic> safeInstructorData = Map<String, dynamic>.from(data);
                    safeInstructorData['id'] = doc.id;

                    final String? imageUrl = safeInstructorData['imageUrl'];
                    final String hoursText = _getDynamicOfficeHoursText(data['officeHours']);

                    return InfoCard(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? AssetImage(imageUrl)
                            : null,
                        child: imageUrl == null || imageUrl.isEmpty
                            ? const Icon(Icons.person, color: AppTheme.primaryColor)
                            : null,
                      ),
                      title: safeInstructorData['name'] ?? '',
                      subtitle: safeInstructorData['department'] ?? '',
                      metadata: hoursText,
                      badge: AppBadge(label: safeInstructorData['title'] ?? ''),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => InstructorDetailScreen(instructorData: safeInstructorData)
                          )
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}