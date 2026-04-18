import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';

class OfficeHoursScreen extends StatefulWidget {
  const OfficeHoursScreen({Key? key}) : super(key: key);

  @override
  State<OfficeHoursScreen> createState() => _OfficeHoursScreenState();
}

class _OfficeHoursScreenState extends State<OfficeHoursScreen> {
  String _searchQuery = "";
  String _selectedFilter = "Tümü";

  final List<String> _filters = ["Tümü", "Pazartesi", "Çarşamba", "Cuma"];

  // Hardcoded based on specification
  final List<Map<String, String>> _officeHours = [
    {"name": "Prof. Dr. Ahmet Yılmaz", "office": "MF-405", "day": "Pazartesi", "time": "10:00-12:00", "dept": "Bilgisayar Mühendisliği"},
    {"name": "Prof. Dr. Ahmet Yılmaz", "office": "MF-405", "day": "Çarşamba", "time": "14:00-16:00", "dept": "Bilgisayar Mühendisliği"},
    {"name": "Doç. Dr. Ayşe Demir", "office": "İİBF-302", "day": "Pazartesi", "time": "13:00-15:00", "dept": "İktisat"},
    {"name": "Doç. Dr. Ayşe Demir", "office": "İİBF-302", "day": "Cuma", "time": "10:00-12:00", "dept": "İktisat"},
    {"name": "Dr. Öğr. Üyesi Mehmet Kaya", "office": "MF-308", "day": "Çarşamba", "time": "10:00-12:00", "dept": "Elektrik-Elektronik Müh."},
    {"name": "Prof. Dr. Fatma Şahin", "office": "FEF-201", "day": "Pazartesi", "time": "14:00-16:00", "dept": "Matematik"},
    {"name": "Prof. Dr. Fatma Şahin", "office": "FEF-201", "day": "Cuma", "time": "13:00-15:00", "dept": "Matematik"},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredHours = _officeHours.where((oh) {
      final matchesSearch = oh["name"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          oh["dept"]!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == "Tümü" || oh["day"] == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: const CustomAppBar(title: "Ofis Saatleri", showBack: true),
      body: Column(
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredHours.length,
              itemBuilder: (context, index) {
                final oh = filteredHours[index];
                return InfoCard(
                  title: oh["name"]!,
                  subtitle: oh["dept"]!,
                  metadata: "${oh["day"]} • ${oh["time"]} | Ofis: ${oh["office"]}",
                  showChevron: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}