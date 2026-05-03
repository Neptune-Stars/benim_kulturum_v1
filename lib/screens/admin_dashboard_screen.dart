import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/data_service.dart';
import '../../widgets/search_bar_widget.dart';
import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;

    String formatted = '';

    for (int i = 0; i < limitedDigits.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += limitedDigits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final limitedDigits = digits.length > 4 ? digits.substring(0, 4) : digits;

    String formatted = '';

    for (int i = 0; i < limitedDigits.length; i++) {
      if (i == 2) {
        formatted += ':';
      }
      formatted += limitedDigits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _tabs = [
    "General", "Units", "Classrooms", "Instructors", "Events", "Announcements", "Cafeteria", "Prices", "Issues", "Students"
  ];

  final Map<int, TextEditingController> _searchControllers = {
    1: TextEditingController(), 2: TextEditingController(), 3: TextEditingController(),
    4: TextEditingController(), 5: TextEditingController(), 6: TextEditingController(),
    7: TextEditingController(), 8: TextEditingController(), 9: TextEditingController(),
  };

  DateTime _cafeteriaWeekStart = DataService.startOfWeek(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _databaseFuture = DataService.loadDatabase();
    });
  }

  @override
  void dispose() {
    for (var controller in _searchControllers.values) { controller.dispose(); }
    _tabController.dispose();
    super.dispose();
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    context.go('/login');
  }

  void _switchTab(int index) { _tabController.animateTo(index); }

  Color _adminPrimaryColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
  }

  Color _adminTextPrimaryColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  }

  Color _adminTextMutedColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
  }

  Color _adminBorderColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppTheme.darkBorderColor : AppTheme.borderColor;
  }

  String _normalizeForSearch(String text) {
    return text.toLowerCase().replaceAll('i̇', 'i').replaceAll('ı', 'i').replaceAll('ğ', 'g')
        .replaceAll('ü', 'u').replaceAll('ş', 's').replaceAll('ö', 'o').replaceAll('ç', 'c');
  }

  void _showDeleteDialog(String collectionKey, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this record? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection(collectionKey).doc(docId).delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted from cloud database.")));
                  _loadData();
                }
              },
              child: const Text("Delete", style: TextStyle(color: AppTheme.destructiveColor))
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, {bool isNumber = false, int lines = 1, bool isPassword = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: lines, obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      List<String> options, {
        String? value,
        Function(String?)? onChanged,
      }) {
    final safeOptions = options.toSet().toList();

    final safeValue = safeOptions.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      selectedItemBuilder: (context) {
        return safeOptions.map((option) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              option,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      items: safeOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(
            option,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  List<String> _getCampusOptions(Map<String, dynamic> data) {
    final campuses = data['campuses'] as List<dynamic>? ?? [];

    final options = campuses
        .map((campus) => (campus['displayName'] ?? campus['name'] ?? '').toString())
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();

    options.sort();

    if (options.isNotEmpty) return options;

    // Fallback only if Firebase campus reference data is not loaded yet.
    return [
      "Atakoy Campus",
      "Incirli Campus",
      "Sirinevler / Bahcelievler Campus",
      "Basin Ekspres / Kucukcekmece Campus",
    ];
  }

  Map<String, List<String>> _getClassroomLocationsByCampus(Map<String, dynamic> data) {
    final campuses = _getCampusOptions(data);
    final locations = data['classroomLocations'] as List<dynamic>? ?? [];

    final Map<String, Set<String>> temp = {
      for (final campus in campuses) campus: <String>{},
    };

    for (final item in locations) {
      final campusName = (item['campusName'] ?? '').toString();
      final locationName = (item['name'] ?? '').toString();

      if (campusName.trim().isEmpty || locationName.trim().isEmpty) continue;

      temp.putIfAbsent(campusName, () => <String>{});
      temp[campusName]!.add(locationName);
    }

    return temp.map((campus, locationSet) {
      final list = locationSet.toList()..sort();

      if (list.isEmpty) {
        list.add("General Building");
      }

      return MapEntry(campus, list);
    });
  }

  String _floorLabelFromValue(dynamic value) {
    final text = value?.toString().trim() ?? "";

    if (text.contains("Floor") || text.contains("Kat")) return text;

    final number = int.tryParse(text);

    if (number == -1) return "Basement";
    if (number == 0) return "Ground Floor";
    if (number == 1) return "1st Floor";
    if (number == 2) return "2nd Floor";
    if (number == 3) return "3rd Floor";
    if (number != null) return "${number}th Floor";

    return "Ground Floor";
  }

  int _floorValueFromLabel(String label) {
    if (label == "Basement" || label == "Bodrum Kat") return -1;
    if (label == "Ground Floor" || label == "Zemin Kat") return 0;

    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match == null) return 0;

    return int.tryParse(match.group(1) ?? "0") ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _switchTab(0),
              child:  Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: _adminPrimaryColor(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text("Admin Panel"),
          ],
        ),
        centerTitle: false,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                tooltip: themeProvider.isDarkMode
                    ? "Switch to Light Mode"
                    : "Switch to Dark Mode",
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                onPressed: () {
                  context.read<ThemeProvider>().toggleTheme();
                },
              );
            },
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(
              Icons.logout,
              color: AppTheme.destructiveColor,
            ),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: _adminPrimaryColor(),
          unselectedLabelColor: _adminTextMutedColor(),
          indicatorColor: _adminPrimaryColor(),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _databaseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No data to display."));

          final data = snapshot.data!;

          final campusOptions = _getCampusOptions(data);
          final classroomLocationsByCampus = _getClassroomLocationsByCampus(data);

          final allBuildings = data['buildings'] as List<dynamic>? ?? [];
          final allClassrooms = data['classrooms'] as List<dynamic>? ?? [];
          final allInstructors = data['instructors'] as List<dynamic>? ?? [];
          final allEvents = data['events'] as List<dynamic>? ?? [];
          final allAnnouncements = data['announcements'] as List<dynamic>? ?? [];

          final allPrices = data['prices'] as List<dynamic>? ?? [];
          final allIssues = data['issues'] as List<dynamic>? ?? [];
          final allStudents = data['students'] as List<dynamic>? ?? [];

          final cafeteriaData = data['cafeteria'] as Map<dynamic, dynamic>? ?? {};
          final menus = cafeteriaData['menus'] as Map<dynamic, dynamic>? ?? {};
          final mealTypes = (cafeteriaData['mealTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              ["Breakfast", "Main Meal", "Fast Food"];

          final sq1 = _normalizeForSearch(_searchControllers[1]!.text);
          final filteredBuildings = allBuildings.where((b) => _normalizeForSearch(b['name'] ?? '').contains(sq1) || _normalizeForSearch(b['location'] ?? '').contains(sq1)).toList();

          final sq2 = _normalizeForSearch(_searchControllers[2]!.text);
          final filteredClassrooms = allClassrooms.where((c) => _normalizeForSearch(c['name'] ?? '').contains(sq2) || _normalizeForSearch(c['building'] ?? '').contains(sq2)).toList();

          final sq3 = _normalizeForSearch(_searchControllers[3]!.text);
          final filteredInstructors = allInstructors.where((i) => _normalizeForSearch(i['name'] ?? '').contains(sq3) || _normalizeForSearch(i['department'] ?? '').contains(sq3)).toList();

          final sq4 = _normalizeForSearch(_searchControllers[4]!.text);
          final filteredEvents = allEvents.where((e) => _normalizeForSearch(e['title'] ?? '').contains(sq4) || _normalizeForSearch(e['date'] ?? '').contains(sq4)).toList();

          final sq5 = _normalizeForSearch(_searchControllers[5]!.text);
          final filteredAnnouncements = allAnnouncements.where((a) => _normalizeForSearch(a['title'] ?? '').contains(sq5) || _normalizeForSearch(a['date'] ?? '').contains(sq5)).toList();

          final sq6 = _normalizeForSearch(_searchControllers[6]!.text);
          final filteredMeals = mealTypes.where((m) => _normalizeForSearch(m).contains(sq6)).toList();

          final sq7 = _normalizeForSearch(_searchControllers[7]!.text);
          final filteredPrices = allPrices.where((p) => _normalizeForSearch(p["name"] ?? '').contains(sq7) || _normalizeForSearch(p["category"] ?? '').contains(sq7)).toList();

          final sq8 = _normalizeForSearch(_searchControllers[8]!.text);
          final filteredIssues = allIssues.where((iss) => _normalizeForSearch(iss["subject"] ?? '').contains(sq8) || _normalizeForSearch(iss["category"] ?? '').contains(sq8)).toList();

          final sq9 = _normalizeForSearch(_searchControllers[9]!.text);
          final filteredStudents = allStudents.where((s) => _normalizeForSearch(s["name"] ?? '').contains(sq9) || _normalizeForSearch(s["no"] ?? '').contains(sq9)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildGenelTab(data),
              _buildManagementTab(
                title: "Campus Units", count: filteredBuildings.length, searchController: _searchControllers[1]!,
                items: filteredBuildings.map((e) => _buildListItem(e['name'] ?? '', e['location'] ?? '', () => _openBuildingForm(isEdit: true, item: e), () => _showDeleteDialog('buildings', e['id'].toString()))).toList(),
                onAdd: () => _openBuildingForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Classrooms",
                count: filteredClassrooms.length,
                searchController: _searchControllers[2]!,
                items: filteredClassrooms.map((e) {
                  final subtitle = [
                    e['campus'],
                    e['location'],
                    e['floorLabel'] ?? _floorLabelFromValue(e['floor']),
                  ].where((value) => value != null && value.toString().trim().isNotEmpty).join(" • ");

                  return _buildListItem(
                    e['name'] ?? '',
                    subtitle,
                        () => _openClassroomForm(
                      isEdit: true,
                      item: e,
                      campusOptions: campusOptions,
                      locationsByCampus: classroomLocationsByCampus,
                    ),
                        () => _showDeleteDialog('classrooms', e['id'].toString()),
                  );
                }).toList(),
                onAdd: () => _openClassroomForm(
                  isEdit: false,
                  campusOptions: campusOptions,
                  locationsByCampus: classroomLocationsByCampus,
                ),
              ),
              _buildManagementTab(
                title: "Instructors", count: filteredInstructors.length, searchController: _searchControllers[3]!,
                items: filteredInstructors.map((e) => _buildListItem(e['name'] ?? '', e['department'] ?? '', () => _openInstructorForm(isEdit: true, item: e), () => _showDeleteDialog('instructors', e['id'].toString()))).toList(),
                onAdd: () => _openInstructorForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Events", count: filteredEvents.length, searchController: _searchControllers[4]!,
                items: filteredEvents.map((e) => _buildListItem(e['title'] ?? '', "${e['date']} - ${e['location']}", () => _openEventForm(isEdit: true, item: e), () => _showDeleteDialog('events', e['id'].toString()))).toList(),
                onAdd: () => _openEventForm(isEdit: false),
              ),
              _buildManagementTab(
                title: "Announcements", count: filteredAnnouncements.length, searchController: _searchControllers[5]!,
                items: filteredAnnouncements.map((e) => _buildListItem(e['title'] ?? '', e['date'] ?? '', () => _openAnnouncementForm(isEdit: true, item: e), () => _showDeleteDialog('announcements', e['id'].toString()))).toList(),
                onAdd: () => _openAnnouncementForm(isEdit: false),
              ),
              _buildCafeteriaWeekTab(),
              _buildManagementTab(
                title: "Prices", count: filteredPrices.length, searchController: _searchControllers[7]!,
                items: filteredPrices.map((p) => _buildListItem(p["name"] ?? '', "${p["price"]} - ${p["category"]}", () => _openPriceForm(isEdit: true, item: p), () => _showDeleteDialog('prices', p['id'].toString()))).toList(),
                onAdd: () => _openPriceForm(isEdit: false),
              ),
              _buildIssuesTab(filteredIssues, _searchControllers[8]!),
              _buildManagementTab(
                title: "Students", count: filteredStudents.length, searchController: _searchControllers[9]!,
                items: filteredStudents.map((s) => _buildListItem(s["name"] ?? '', "${s["no"]} - ${s["grade"]}", () => _openStudentForm(isEdit: true, item: s), () => _showDeleteDialog('students', s['id'].toString()))).toList(),
                onAdd: () => _openStudentForm(isEdit: false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCafeteriaWeekTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DataService.fetchWeeklyCafeteriaMenus(
        weekStart: _cafeteriaWeekStart,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text("Could not retrieve weekly cafeteria data."),
          );
        }

        final days = snapshot.data ?? [];
        final weekEnd = _cafeteriaWeekStart.add(const Duration(days: 6));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Cafeteria Menus",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "Previous week",
                        onPressed: () {
                          setState(() {
                            _cafeteriaWeekStart = _cafeteriaWeekStart.subtract(
                              const Duration(days: 7),
                            );
                          });
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        tooltip: "Next week",
                        onPressed: () {
                          setState(() {
                            _cafeteriaWeekStart = _cafeteriaWeekStart.add(
                              const Duration(days: 7),
                            );
                          });
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${DataService.formatDisplayDate(_cafeteriaWeekStart)} - ${DataService.formatDisplayDate(weekEnd)}",
                    style: TextStyle(
                      color: _adminTextMutedColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "If you uncheck a day, students will see that there is no food for that day. When active, you can edit Breakfast, Main Meal, and Fast Food items.",
                    style: TextStyle(
                      color: _adminTextMutedColor(),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.25,
                children: days.map((day) => _buildCafeteriaDayCard(day)).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCafeteriaDayCard(Map<String, dynamic> day) {
    final date = day['date'] as DateTime;
    final isWeekend = day['isWeekend'] == true;
    final isDayActive = day['isDayActive'] != false;

    final titleColor = !isDayActive
        ? _adminTextMutedColor()
        : (isWeekend ? _adminPrimaryColor() : _adminTextPrimaryColor());

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: isDayActive ? () => _openDailyCafeteriaDialog(date) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDayActive
              ? Theme.of(context).cardColor
              : Theme.of(context).cardColor.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: !isDayActive
                ? _adminTextMutedColor().withOpacity(0.35)
                : (isWeekend
                ? _adminPrimaryColor().withOpacity(0.35)
                : Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day['weekday']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day['displayDate']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _adminTextMutedColor(), fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isDayActive ? "Close day" : "Open day",
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleCafeteriaDayActive(date, !isDayActive),
              icon: Icon(
                isDayActive ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDayActive ? _adminPrimaryColor() : _adminTextMutedColor(),
                size: 20,
              ),
            ),
            IconButton(
              tooltip: isDayActive ? "Edit day" : "Day is closed",
              visualDensity: VisualDensity.compact,
              onPressed: isDayActive ? () => _openDailyCafeteriaDialog(date) : null,
              icon: Icon(
                Icons.edit,
                size: 18,
                color: isDayActive ? _adminPrimaryColor() : _adminTextMutedColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCafeteriaDayActive(DateTime date, bool nextValue) async {
    await DataService.setCafeteriaDayActiveStatus(date, nextValue);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? "${DataService.weekdayName(date.weekday)} is open for students again."
                : "${DataService.weekdayName(date.weekday)} is closed for students.",
          ),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _toggleDailyMenuActive({
    required DateTime date,
    required String mealType,
    required bool nextValue,
    VoidCallback? onSaved,
  }) async {
    await DataService.setDailyMenuActiveStatus(
      date: date,
      mealType: mealType,
      isActive: nextValue,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? "$mealType is now visible to students."
                : "$mealType is hidden from students.",
          ),
        ),
      );
      onSaved?.call();
      setState(() {});
    }
  }

  void _openDailyCafeteriaDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                "${DataService.weekdayName(date.weekday)} Menu",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: DataService.fetchCafeteriaDayStatus(date),
                  builder: (context, daySnapshot) {
                    if (daySnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final dayStatus = daySnapshot.data ?? {};
                    final isDayActive = dayStatus['isDayActive'] != false;

                    if (!isDayActive) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "This day is closed for students.",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "If you check the day again, students can see it and menus can be edited.",
                            style: TextStyle(color: _adminTextMutedColor(), height: 1.35),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await DataService.setCafeteriaDayActiveStatus(date, true);
                              setDialogState(() {});
                              setState(() {});
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text("Open Day"),
                          ),
                        ],
                      );
                    }

                    return FutureBuilder<Map<String, Map<String, dynamic>>>(
                      future: DataService.fetchDailyCafeteriaMenus(date),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 120,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final menus = snapshot.data ?? {};

                        return SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: DataService.cafeteriaMealTypes.map((mealType) {
                              final menu = menus[mealType] ??
                                  DataService.defaultMenuForMealType(mealType);
                              final items = menu['items'] as List<dynamic>? ?? [];
                              final isMenuActive = menu['isActive'] != false;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                color: isMenuActive
                                    ? Theme.of(context).cardColor
                                    : Theme.of(context).cardColor.withOpacity(0.55),
                                child: ListTile(
                                  title: Text(
                                    menu['menuName']?.toString() ?? mealType,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isMenuActive
                                          ? AppTheme.textPrimary
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "$mealType • ${menu['time'] ?? '-'} • ${menu['price'] ?? '-'} • ${items.length} items",
                                    style: TextStyle(
                                      color: isMenuActive
                                          ? AppTheme.textMuted
                                          : AppTheme.textMuted.withOpacity(0.75),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: isMenuActive ? "Hide from students" : "Show to students",
                                        onPressed: () => _toggleDailyMenuActive(
                                          date: date,
                                          mealType: mealType,
                                          nextValue: !isMenuActive,
                                          onSaved: () {
                                            setDialogState(() {});
                                            setState(() {});
                                          },
                                        ),
                                        icon: Icon(
                                          isMenuActive
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: isMenuActive
                                              ? AppTheme.successColor
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: "Edit menu",
                                        onPressed: () => _openDailyMenuForm(
                                          date: date,
                                          mealType: mealType,
                                          item: menu,
                                          onSaved: () {
                                            setDialogState(() {});
                                            setState(() {});
                                          },
                                        ),
                                        icon: const Icon(
                                          Icons.edit,
                                          color: AppTheme.primaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openDailyMenuForm({
    required DateTime date,
    required String mealType,
    required Map<dynamic, dynamic> item,
    VoidCallback? onSaved,
  }) {
    final normalizedMealType = DataService.normalizeMealType(mealType);
    final isFastFood = normalizedMealType == "Fast Food";

    final menuNameCtrl = TextEditingController(
      text: item['menuName']?.toString() ??
          DataService.defaultMenuForMealType(normalizedMealType)['menuName']?.toString() ??
          normalizedMealType,
    );
    final timeCtrl = TextEditingController(text: item['time']?.toString() ?? "");
    final priceCtrl = TextEditingController(text: item['price']?.toString() ?? "");
    final itemsListText = isFastFood ? "" : (item['items'] as List<dynamic>? ?? []).join(", ");
    final itemsCtrl = TextEditingController(text: itemsListText);

    final List<Map<String, TextEditingController>> productControllers = [];
    if (isFastFood) {
      final sourceItems = item['items'] as List<dynamic>? ?? [];
      for (final product in sourceItems) {
        if (product is Map) {
          productControllers.add({
            "name": TextEditingController(text: product['name']?.toString() ?? ""),
            "price": TextEditingController(text: product['price']?.toString() ?? ""),
          });
        } else {
          productControllers.add({
            "name": TextEditingController(text: product.toString()),
            "price": TextEditingController(text: "₺0"),
          });
        }
      }

      if (productControllers.isEmpty) {
        productControllers.add({
          "name": TextEditingController(),
          "price": TextEditingController(),
        });
      }
    }

    showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                  title: Text(
                    "${DataService.weekdayName(date.weekday)} - $normalizedMealType",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: menuNameCtrl,
                          decoration: const InputDecoration(
                            labelText: "Menu Name",
                            hintText: "E.g.: Today's Meal",
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: timeCtrl,
                          decoration: const InputDecoration(
                            labelText: "Time Range",
                            hintText: "E.g.: 13:00-18:00",
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: priceCtrl,
                          decoration: InputDecoration(
                            labelText: isFastFood ? "General Price Info" : "Price",
                            hintText: isFastFood ? "Item based" : "E.g.: ₺35",
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!isFastFood)
                          TextField(
                            controller: itemsCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: "Content / Meals",
                              hintText: "Separate with commas: Soup, Chicken, Rice",
                            ),
                          )
                        else ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Fast Food Items",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...productControllers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final controllers = entry.value;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: controllers["name"],
                                      decoration: InputDecoration(
                                        labelText: "Item ${index + 1}",
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: controllers["price"],
                                      decoration: const InputDecoration(
                                        labelText: "Price",
                                        hintText: "₺40",
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: productControllers.length == 1
                                        ? null
                                        : () {
                                      setDialogState(() {
                                        productControllers.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  productControllers.add({
                                    "name": TextEditingController(),
                                    "price": TextEditingController(),
                                  });
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text("Add Item"),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                  TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
              ),
              ElevatedButton(
              onPressed: () async {
              final rawPrice = priceCtrl.text.trim();
              final normalizedPrice = isFastFood
              ? (rawPrice.isEmpty ? "Item based" : rawPrice)
                  : (rawPrice.isEmpty
              ? ""
                  : rawPrice.startsWith("₺")
              ? rawPrice
                  : "₺$rawPrice");

              List<dynamic> newItems;

              if (isFastFood) {
                newItems = productControllers.map((controllers) {
                  final name = controllers["name"]!.text.trim();
                  final price = controllers["price"]!.text.trim();
                  final normalizedProductPrice = price.isEmpty
                      ? "₺0"
                      : price.startsWith("₺")
                      ? price
                      : "₺$price";

                  return {
                    "name": name,
                    "price": normalizedProductPrice,
                  };
                }).where((product) {
                  return product["name"].toString().trim().isNotEmpty;
                }).toList();
              } else {
                newItems = itemsCtrl.text
                    .split(",")
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }

              if (newItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Menu content cannot be empty.")),
                );
                return;
              }

              final menuData = {
                "menuName": menuNameCtrl.text.trim().isEmpty
                    ? normalizedMealType
                    : menuNameCtrl.text.trim(),
                "time": timeCtrl.text.trim(),
                "price": normalizedPrice,
                "items": newItems,
                "isActive": item['isActive'] ?? true,
                "isChips": item['isChips'] ?? false,
              };

              final docId = DataService.cafeteriaMenuDocId(
                date: date,
                mealType: normalizedMealType,
              );

              await FirebaseFirestore.instance
                  .collection('cafeteriaMenus')
                  .doc(docId)
                  .set(
                DataService.buildCafeteriaMenuDocument(
                  date: date,
                  mealType: normalizedMealType,
                  menu: menuData,
                ),
                SetOptions(merge: true),
              );

              if (context.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Daily menu updated in Firebase database."),
                  ),
                );
                onSaved?.call();
                setState(() {});
              }
              },
                child: const Text("Save"),
              ),
                  ],
              );
            },
        ),
    );
  }

  Widget _buildGenelTab(Map<String, dynamic> data) {
    final bCount = (data['buildings'] as List?)?.length ?? 0;
    final cCount = (data['classrooms'] as List?)?.length ?? 0;
    final iCount = (data['instructors'] as List?)?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.primaryLight.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3))),
            child: const Row(
              children: [
                Icon(Icons.cloud_done, color: AppTheme.primaryColor),
                SizedBox(width: 12),
                Expanded(child: Text("Google Firebase Cloud Active", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.25,
            children: [
              _buildStatCard(Icons.business, "Units", bCount.toString(), 1),
              _buildStatCard(Icons.meeting_room, "Classrooms", cCount.toString(), 2),
              _buildStatCard(Icons.people, "Instructors", iCount.toString(), 3),
              _buildStatCard(Icons.event, "Events", ((data['events'] as List?)?.length ?? 0).toString(), 4),
              _buildStatCard(Icons.report_problem, "Issues", ((data['issues'] as List?)?.length ?? 0).toString(), 8),
              _buildStatCard(Icons.person, "Students", ((data['students'] as List?)?.length ?? 0).toString(), 9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, int tabIndex) {
    return InkWell(
      onTap: () => _switchTab(tabIndex),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _adminBorderColor()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: _adminPrimaryColor(),
                ),
                Icon(
                  Icons.chevron_right,
                  color: _adminTextMutedColor(),
                  size: 20,
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _adminTextPrimaryColor(),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: _adminTextMutedColor(),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTab({required String title, required int count, required List<Widget> items, required VoidCallback onAdd, required TextEditingController searchController}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$title ($count)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text("Add"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AppSearchBar(controller: searchController, placeholder: "Search...", onChanged: (val) => setState(() {})),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: items.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (context, index) => items[index],
          ),
        )
      ],
    );
  }

  Widget _buildListItem(
      String title,
      String subtitle,
      VoidCallback onEdit,
      VoidCallback? onDelete,
      ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _adminTextPrimaryColor(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: _adminTextMutedColor(),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.edit,
            color: _adminPrimaryColor(),
          ),
          onPressed: onEdit,
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: AppTheme.destructiveColor,
            ),
            onPressed: onDelete,
          ),
      ],
    );
  }

  Widget _buildIssuesTab(List<dynamic> issues, TextEditingController searchController) {
    final openIssues = issues.where((issue) {
      final status = (issue["status"] ?? "Open").toString();
      return status != "Resolved";
    }).toList();

    final resolvedIssues = issues.where((issue) {
      final status = (issue["status"] ?? "Open").toString();
      return status == "Resolved";
    }).toList();

    final sortedIssues = [...openIssues, ...resolvedIssues];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Gelen Sorunlar (${issues.length})",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AppSearchBar(
            controller: searchController,
            placeholder: "Search subject or location...",
            onChanged: (val) => setState(() {}),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: sortedIssues.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final issue = sortedIssues[index];

              final status = (issue["status"] ?? "Open").toString();
              final isResolved = status == "Resolved";

              Color priorityColor = issue["priority"] == "High"
                  ? AppTheme.destructiveColor
                  : (issue["priority"] == "Medium"
                  ? AppTheme.warningColor
                  : AppTheme.successColor);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        issue["priority"] ?? '',
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isResolved
                            ? AppTheme.successColor.withOpacity(0.1)
                            : AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isResolved
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue["subject"] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: isResolved
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "${issue["category"]} • ${issue["location"]}\n${issue["date"]}",
                    style: TextStyle(color: _adminTextMutedColor()),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye, color: AppTheme.primaryLight),
                      onPressed: () => _openIssueDetailsDialog(issue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.destructiveColor),
                      onPressed: () => _showDeleteDialog(
                        'issues',
                        (issue['firestoreDocId'] ?? issue['id']).toString(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openIssueDetailsDialog(Map<dynamic, dynamic> issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Issue Details", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Subject: ${issue["subject"]}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Text("Category: ${issue["category"]}", style: const TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text("Location: ${issue["location"]}", style: const TextStyle(color: AppTheme.textMuted)),
              const Divider(height: 24),
              Text(issue["description"] ?? '', style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton.icon(
            onPressed: () async {

              // Mark issue as resolved instead of deleting it
              await FirebaseFirestore.instance
                  .collection('issues')
                  .doc((issue['firestoreDocId'] ?? issue['id']).toString())
                  .update({
                "status": "Resolved",
                "resolvedAt": FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Issue marked as resolved.")),
                );
                _loadData();
              }
            },
            icon: const Icon(Icons.check, size: 18), label: const Text("Resolved"),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openStudentForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final noCtrl = TextEditingController(text: item?['no']);
    final emailCtrl = TextEditingController(text: item?['email']);
    final passCtrl = TextEditingController(text: item?['password']);

    final List<String> gradeOptions = ["Prep", "1st Grade", "2nd Grade", "3rd Grade", "4th Grade", "Alumni"];
    String? selectedGrade = item?['grade'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? "Edit — Student" : "Add New Student", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField("Full Name", controller: nameCtrl),
                    const SizedBox(height: 12),
                    _buildTextField("Student No", isNumber: true, controller: noCtrl),
                    const SizedBox(height: 12),
                    _buildTextField("Email", controller: emailCtrl),
                    const SizedBox(height: 12),
                    _buildTextField("Password", controller: passCtrl),
                    const SizedBox(height: 12),
                    _buildDropdown("Grade", gradeOptions, value: gradeOptions.contains(selectedGrade) ? selectedGrade : null, onChanged: (val) => setDialogState(() => selectedGrade = val)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      int docId = isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch;
                      Map<String, dynamic> newData = {
                        'id': docId,
                        'name': nameCtrl.text,
                        'no': noCtrl.text,
                        'email': emailCtrl.text,
                        'password': passCtrl.text,
                        'grade': selectedGrade ?? '1st Grade'
                      };
                      await FirebaseFirestore.instance.collection('students').doc(docId.toString()).set(newData);
                      if (context.mounted) { Navigator.pop(context); _loadData(); }
                    },
                    child: const Text("Save")
                )
              ],
            );
          }
      ),
    );
  }

  void _openPriceForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final priceCtrl = TextEditingController(text: item?['price']?.replaceAll('₺', ''));

    final List<String> catOptions = ["Tea/Coffee", "Beverages", "Snacks", "Meal"];
    String? selectedCat = item?['category'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? "Edit — Price" : "Add New Price", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDropdown("Category", catOptions, value: catOptions.contains(selectedCat) ? selectedCat : null, onChanged: (val) => setDialogState(() => selectedCat = val)),
                    const SizedBox(height: 12),
                    _buildTextField("Product Name", controller: nameCtrl),
                    const SizedBox(height: 12),
                    _buildTextField("Price", isNumber: true, controller: priceCtrl),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      int docId = isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch;
                      Map<String, dynamic> newData = {
                        'id': docId,
                        'name': nameCtrl.text,
                        'price': "₺${priceCtrl.text}",
                        'category': selectedCat ?? 'Tea/Coffee'
                      };
                      await FirebaseFirestore.instance.collection('prices').doc(docId.toString()).set(newData);
                      if (context.mounted) { Navigator.pop(context); _loadData(); }
                    },
                    child: const Text("Save")
                )
              ],
            );
          }
      ),
    );
  }

  void _openBuildingForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final List<String> campusOptions = ["Atakoy", "Incirli", "Basin Ekspres", "Sirinevler"];
    final List<String> locationOptions = ["Ground Floor", "1st Floor", "2nd Floor", "3rd Floor", "4th Floor", "5th Floor", "Basement", "Garden"];
    String? selectedCampus;
    String? selectedLocation;

    String? _matchOption(List<String> options, String? rawValue) {
      if (rawValue == null) return null;
      final value = rawValue.trim();
      if (value.isEmpty) return null;

      if (options.contains(value)) return value;

      final lowerValue = value.toLowerCase();
      for (final opt in options) {
        final lowerOpt = opt.toLowerCase();
        if (lowerOpt.contains(lowerValue) || lowerValue.contains(lowerOpt)) {
          return opt;
        }
      }
      return null;
    }

    if (item != null && item['location'] != null) {
      String loc = item['location'].toString();
      String rawCampus;
      String? rawLocation;

      if (loc.contains(',')) {
        var parts = loc.split(',');
        rawCampus = parts[0].trim();
        rawLocation = parts.length > 1 ? parts[1].trim() : null;
      } else {
        rawCampus = loc.trim();
        rawLocation = null;
      }

      selectedCampus = _matchOption(campusOptions, rawCampus);
      selectedLocation = _matchOption(locationOptions, rawLocation);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? "Edit: Unit/Area" : "Add New Unit", style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Unit Name (E.g.: Faculty of Law)")),
                  const SizedBox(height: 12),
                  _buildDropdown("Select Campus", campusOptions, value: selectedCampus, onChanged: (val) => setDialogState(() => selectedCampus = val)),
                  const SizedBox(height: 12),
                  _buildDropdown("Select Floor/Location", locationOptions, value: selectedLocation, onChanged: (val) => setDialogState(() => selectedLocation = val)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                  onPressed: () async {
                    String finalLocation = "${selectedCampus ?? 'Not Specified'}, ${selectedLocation ?? 'Not Specified'}";
                    int docId = isEdit ? item!['id'] : DateTime.now().millisecondsSinceEpoch;
                    Map<String, dynamic> newData = {
                      'id': docId, 'name': nameCtrl.text, 'location': finalLocation,
                      'abbr': item?['abbr'] ?? 'NEW', 'type': item?['type'] ?? 'faculty'
                    };
                    await FirebaseFirestore.instance.collection('buildings').doc(docId.toString()).set(newData);
                    if (context.mounted) { Navigator.pop(context); _loadData(); }
                  },
                  child: const Text("Save")
              )
            ],
          );
        },
      ),
    );
  }

  void _openClassroomForm({
    required bool isEdit,
    Map<dynamic, dynamic>? item,
    required List<String> campusOptions,
    required Map<String, List<String>> locationsByCampus,
  }) {
    final nameCtrl = TextEditingController(text: item?['name']?.toString() ?? '');
    final capacityCtrl = TextEditingController(text: (item?['capacity'] ?? 40).toString());

    final List<String> floorOptions = [
      "Basement",
      "Ground Floor",
      "1st Floor",
      "2nd Floor",
      "3rd Floor",
      "4th Floor",
      "5th Floor",
      "6th Floor",
      "7th Floor",
      "8th Floor",
    ];

    final List<String> typeOptions = [
      "Classroom",
      "Amphitheater",
      "Laboratory",
    ];

    String? selectedCampus = item?['campus']?.toString();
    String? selectedLocation = item?['location']?.toString();
    String? selectedFloor = item?['floorLabel']?.toString();
    String? selectedType = item?['type']?.toString();

    if ((selectedCampus == null || selectedCampus.trim().isEmpty) && item?['building'] != null) {
      final buildingText = item!['building'].toString();

      if (buildingText.contains(',')) {
        final parts = buildingText.split(',');
        selectedCampus = parts.first.trim();
      } else {
        selectedCampus = buildingText.trim();
      }
    }

    if ((selectedFloor == null || selectedFloor.trim().isEmpty) && item?['floor'] != null) {
      selectedFloor = _floorLabelFromValue(item!['floor']);
    }

    if (selectedCampus != null && !campusOptions.contains(selectedCampus)) {
      final match = campusOptions.where((campus) {
        return campus.toLowerCase().contains(selectedCampus!.toLowerCase()) ||
            selectedCampus!.toLowerCase().contains(campus.toLowerCase());
      }).toList();

      selectedCampus = match.isNotEmpty ? match.first : null;
    }

    selectedCampus ??= campusOptions.isNotEmpty ? campusOptions.first : null;

    List<String> currentLocationOptions = selectedCampus == null
        ? <String>[]
        : (locationsByCampus[selectedCampus] ?? <String>["General Building"]);

    if (selectedLocation == null || !currentLocationOptions.contains(selectedLocation)) {
      selectedLocation = currentLocationOptions.isNotEmpty ? currentLocationOptions.first : null;
    }

    if (selectedFloor == null || !floorOptions.contains(selectedFloor)) {
      selectedFloor = "Ground Floor";
    }

    if (selectedType == null || !typeOptions.contains(selectedType)) {
      selectedType = "Classroom";
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          currentLocationOptions = selectedCampus == null
              ? <String>[]
              : (locationsByCampus[selectedCampus] ?? <String>["General Building"]);

          return AlertDialog(
            title: Text(
              isEdit ? "Edit: Classroom" : "New Classroom",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Classroom Name"),
                  ),
                  const SizedBox(height: 12),

                  _buildDropdown(
                    "Campus",
                    campusOptions,
                    value: campusOptions.contains(selectedCampus) ? selectedCampus : null,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCampus = val;
                        final nextLocations = locationsByCampus[selectedCampus] ?? <String>["General Building"];
                        selectedLocation = nextLocations.isNotEmpty ? nextLocations.first : null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildDropdown(
                    "Location / Building",
                    currentLocationOptions,
                    value: currentLocationOptions.contains(selectedLocation) ? selectedLocation : null,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedLocation = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildDropdown(
                    "Floor",
                    floorOptions,
                    value: floorOptions.contains(selectedFloor) ? selectedFloor : null,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedFloor = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildDropdown(
                    "Classroom Type",
                    typeOptions,
                    value: typeOptions.contains(selectedType) ? selectedType : null,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedType = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: capacityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Capacity"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final capacity = int.tryParse(capacityCtrl.text.trim()) ?? 40;

                  if (name.isEmpty ||
                      selectedCampus == null ||
                      selectedLocation == null ||
                      selectedFloor == null ||
                      selectedType == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill classroom name, campus, location, floor and type fields.")),
                    );
                    return;
                  }

                  final int docId = isEdit
                      ? int.tryParse(item!['id'].toString()) ?? DateTime.now().millisecondsSinceEpoch
                      : DateTime.now().millisecondsSinceEpoch;

                  final Map<String, dynamic> newData = {
                    'id': docId,
                    'name': name,
                    'campus': selectedCampus,
                    'location': selectedLocation,
                    'floor': _floorValueFromLabel(selectedFloor!),
                    'floorLabel': selectedFloor,
                    'building': "$selectedCampus, $selectedLocation",
                    'capacity': capacity,
                    'type': selectedType,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  await FirebaseFirestore.instance
                      .collection('classrooms')
                      .doc(docId.toString())
                      .set(newData, SetOptions(merge: true));

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Classroom saved to Firebase database.")),
                    );
                    _loadData();
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openInstructorForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final nameCtrl = TextEditingController(text: item?['name']);
    final deptCtrl = TextEditingController(text: item?['department']);
    final photoCtrl = TextEditingController(text: item?['imageUrl'] ?? '');

    final officeHoursCtrl = TextEditingController(
        text: (item?['officeHours'] is List)
            ? (item?['officeHours'] as List).join(", ")
            : ""
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit: Instructor" : "New Instructor", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
              const SizedBox(height: 12),
              TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: "Department")),
              const SizedBox(height: 12),
              TextField(
                  controller: officeHoursCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: "Office Hours",
                      hintText: "E.g.: Mon 10:00-12:00, Tue 14:00-16:00",
                      helperText: "Separate days with commas.",
                      helperStyle: TextStyle(fontSize: 10)
                  )
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: photoCtrl,
                  decoration: const InputDecoration(
                      labelText: "Photo Path",
                      hintText: "assets/instructors/default.jpg"
                  )
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                List<String> hoursList = officeHoursCtrl.text
                    .split(",")
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                String docId = isEdit ? item!['id'].toString() : DateTime.now().millisecondsSinceEpoch.toString();

                Map<String, dynamic> newData = {
                  'id': docId,
                  'name': nameCtrl.text,
                  'department': deptCtrl.text,
                  'imageUrl': photoCtrl.text,
                  'officeHours': hoursList,
                  'title': item?['title'] ?? 'Faculty Member',
                  'office': item?['office'] ?? 'Unknown',
                  'filter': item?['filter'] ?? 'engineering',
                  'email': item?['email'] ?? 'contact@uni.edu.tr'
                };

                await FirebaseFirestore.instance.collection('instructors').doc(docId).set(newData);

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text("Save")
          )
        ],
      ),
    );
  }

  void _openEventForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final titleCtrl = TextEditingController(text: item?['title'] ?? '');
    final dateCtrl = TextEditingController(text: item?['date'] ?? '');
    final timeCtrl = TextEditingController(text: item?['time'] ?? '');
    final locCtrl = TextEditingController(text: item?['location'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');

    final List<String> categoryOptions = [
      "General",
      "Academic",
      "Culture Art",
      "Sports",
      "Seminar",
      "Club",
      "Career",
    ];

    String? selectedCategory = item?['category'] ?? "General";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEdit ? "Edit: Event" : "New Event",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Event Title",
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(
                      labelText: "Date",
                      hintText: "E.g.: April 28",
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Time",
                      hintText: "E.g.: 14:00",
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: locCtrl,
                    decoration: const InputDecoration(
                      labelText: "Location",
                      hintText: "E.g.: Atakoy Campus / Conference Hall",
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildDropdown(
                    "Category",
                    categoryOptions,
                    value: categoryOptions.contains(selectedCategory)
                        ? selectedCategory
                        : "General",
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCategory = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      hintText: "Enter a brief description of the event.",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final date = dateCtrl.text.trim();
                  final time = timeCtrl.text.trim();
                  final location = locCtrl.text.trim();
                  final description = descCtrl.text.trim();

                  if (title.isEmpty || date.isEmpty || location.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Title, date and location fields are required."),
                      ),
                    );
                    return;
                  }

                  final int docId = isEdit
                      ? int.tryParse(item!['id'].toString()) ??
                      DateTime.now().millisecondsSinceEpoch
                      : DateTime.now().millisecondsSinceEpoch;

                  final Map<String, dynamic> newData = {
                    'id': docId,
                    'title': title,
                    'date': date,
                    'time': time,
                    'location': location,
                    'category': selectedCategory ?? 'General',
                    'description': description.isEmpty
                        ? 'No details entered.'
                        : description,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (!isEdit) {
                    newData['createdAt'] = FieldValue.serverTimestamp();
                  }

                  await FirebaseFirestore.instance
                      .collection('events')
                      .doc(docId.toString())
                      .set(newData, SetOptions(merge: true));


                  if (!isEdit) {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc('event_$docId')
                        .set({
                      'id': 'event_$docId',
                      'title': title,
                      'subtitle': "$date ${time.isNotEmpty ? '• $time' : ''} • $location",
                      'type': 'event',
                      'isRead': false,
                      'createdAt': FieldValue.serverTimestamp(),
                      'sourceCollection': 'events',
                      'sourceId': docId.toString(),
                    });
                  }


                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Event saved to Firebase database."),
                      ),
                    );
                    _loadData();
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAnnouncementForm({required bool isEdit, Map<dynamic, dynamic>? item}) {
    final titleCtrl = TextEditingController(text: item?['title'] ?? '');
    final contentCtrl = TextEditingController(text: item?['content'] ?? '');
    final publishDateCtrl = TextEditingController(
      text: item?['publishDate'] ?? '',
    );
    final publishTimeCtrl = TextEditingController(
      text: item?['publishTime'] ?? '',
    );

    final List<String> categoryOptions = [
      "general",
      "academic",
      "admin",
      "scholarship",
    ];

    String? selectedCategory = item?['category'] ?? "general";

    DateTime? _tryBuildPublishDateTime(String dateText, String timeText) {
      final dateParts = dateText.trim().split('/');
      final timeParts = timeText.trim().split(':');

      if (dateParts.length != 3 || timeParts.length != 2) return null;

      final day = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final year = int.tryParse(dateParts[2]);
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (day == null ||
          month == null ||
          year == null ||
          hour == null ||
          minute == null) {
        return null;
      }

      if (year < 2024 ||
          month < 1 ||
          month > 12 ||
          day < 1 ||
          day > 31 ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        return null;
      }

      final parsedDate = DateTime(year, month, day, hour, minute);

      final isSameDate =
          parsedDate.year == year &&
              parsedDate.month == month &&
              parsedDate.day == day &&
              parsedDate.hour == hour &&
              parsedDate.minute == minute;

      if (!isSameDate) return null;

      return parsedDate;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEdit ? "Edit: Announcement" : "New Announcement",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: publishDateCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      DateInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Date to Display",
                      hintText: "DD/MM/YYYY",
                    ),
                  ),

                  TextField(
                    controller: publishTimeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TimeInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Time to Display",
                      hintText: "HH:MM",
                    ),
                  ),

                  _buildDropdown(
                    "Category",
                    categoryOptions,
                    value: categoryOptions.contains(selectedCategory)
                        ? selectedCategory
                        : "general",
                    onChanged: (val) {
                      setDialogState(() {
                        selectedCategory = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Content",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final content = contentCtrl.text.trim();
                  final publishDate = publishDateCtrl.text.trim();
                  final publishTime = publishTimeCtrl.text.trim();

                  if (title.isEmpty || content.isEmpty || publishDate.isEmpty || publishTime.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Title, content, date and time to display are required."),
                      ),
                    );
                    return;
                  }

                  final publishDateTime = _tryBuildPublishDateTime(publishDate, publishTime);

                  if (publishDateTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Date must be DD/MM/YYYY, time must be HH:MM format. E.g.: 28/04/2026 and 13:45"),
                      ),
                    );
                    return;
                  }

                  final int docId = isEdit
                      ? int.tryParse(item!['id'].toString()) ??
                      DateTime.now().millisecondsSinceEpoch
                      : DateTime.now().millisecondsSinceEpoch;

                  final Map<String, dynamic> newData = {
                    'id': docId,
                    'title': title,
                    'content': content,
                    'category': selectedCategory ?? 'general',
                    'date': publishDate,
                    'publishDate': publishDate,
                    'publishTime': publishTime,
                    'publishAt': Timestamp.fromDate(publishDateTime),
                    'isNew': true,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (!isEdit) {
                    newData['createdAt'] = FieldValue.serverTimestamp();
                  }

                  await FirebaseFirestore.instance
                      .collection('announcements')
                      .doc(docId.toString())
                      .set(newData, SetOptions(merge: true));

                  if (!isEdit) {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc('announcement_$docId')
                        .set({
                      'id': 'announcement_$docId',
                      'title': title,
                      'subtitle': content,
                      'type': 'announcement',
                      'isRead': false,
                      'createdAt': FieldValue.serverTimestamp(),
                      'sourceCollection': 'announcements',
                      'sourceId': docId.toString(),
                    });
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Announcement saved to Firebase database."),
                      ),
                    );
                    _loadData();
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openMenuForm({
    required bool isEdit,
    required String mealName,
    required Map<dynamic, dynamic> item,
    required Map<dynamic, dynamic> fullCafeteriaData,
  }) {
    final nameCtrl = TextEditingController(text: mealName);

    final menuNameCtrl = TextEditingController(
      text: item['menuName']?.toString() ??
          (mealName == "Main Meal"
              ? "Today's Meal"
              : mealName.isNotEmpty
              ? "$mealName Menu"
              : ""),
    );

    final timeCtrl = TextEditingController(text: item['time']?.toString() ?? "");
    final priceCtrl = TextEditingController(text: item['price']?.toString() ?? "");

    final List<dynamic> currentItems = item['items'] as List<dynamic>? ?? [];
    final bool isFastFood = mealName == "Fast Food";

    final itemsListText = currentItems.map((item) {
      if (item is Map) {
        return item['name']?.toString() ?? '';
      }
      return item.toString();
    }).where((name) => name.trim().isNotEmpty).join(", ");

    final itemsCtrl = TextEditingController(text: itemsListText);

    final List<TextEditingController> productNameControllers = [];
    final List<TextEditingController> productPriceControllers = [];

    String normalizePrice(String rawPrice) {
      final trimmed = rawPrice.trim();
      if (trimmed.isEmpty) return "₺0";
      if (trimmed == "Item based") return trimmed;
      return trimmed.startsWith("₺") ? trimmed : "₺$trimmed";
    }

    void addProductController({String name = "", String price = ""}) {
      productNameControllers.add(TextEditingController(text: name));
      productPriceControllers.add(TextEditingController(text: price));
    }

    if (isFastFood) {
      for (final product in currentItems) {
        if (product is Map) {
          addProductController(
            name: product['name']?.toString() ?? '',
            price: product['price']?.toString() ?? '',
          );
        } else {
          addProductController(name: product.toString(), price: '₺0');
        }
      }

      if (productNameControllers.isEmpty) {
        addProductController();
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(
              isEdit ? "Edit Menu: $mealName" : "Add New Menu",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEdit) ...[
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Category / Menu Type",
                        hintText: "E.g.: Breakfast, Main Meal, Fast Food",
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: menuNameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Menu Name",
                      hintText: "E.g.: Today's Meal",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Time Range",
                      hintText: "E.g.: 13:00-18:00",
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (isFastFood) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        "Fast Food items are priced per item.",
                        style: TextStyle(
                          color: _adminTextMutedColor(),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(productNameControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: productNameControllers[index],
                                decoration: InputDecoration(
                                  labelText: "Product ${index + 1}",
                                  hintText: "E.g.: Toast",
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: productPriceControllers[index],
                                decoration: const InputDecoration(
                                  labelText: "Price",
                                  hintText: "₺40",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.destructiveColor,
                              ),
                              onPressed: productNameControllers.length == 1
                                  ? null
                                  : () {
                                setDialogState(() {
                                  productNameControllers.removeAt(index);
                                  productPriceControllers.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            addProductController();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add Product"),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: "Price",
                        hintText: "E.g.: ₺35",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: itemsCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Content / Meals",
                        hintText: "Separate with commas: Soup, Chicken, Rice, Ayran",
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String newMealName = isEdit ? mealName : nameCtrl.text.trim();

                  if (newMealName == "Lunch" ||
                      newMealName == "Dinner" ||
                      newMealName == "Today's Menu") {
                    newMealName = "Main Meal";
                  }

                  if (newMealName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Category name cannot be empty.")),
                    );
                    return;
                  }

                  final bool saveAsFastFood = newMealName == "Fast Food";
                  late final List<dynamic> newItems;
                  late final String normalizedPrice;

                  if (saveAsFastFood) {
                    final products = <Map<String, dynamic>>[];

                    for (int i = 0; i < productNameControllers.length; i++) {
                      final productName = productNameControllers[i].text.trim();
                      final productPrice = productPriceControllers[i].text.trim();

                      if (productName.isEmpty) continue;

                      products.add({
                        "name": productName,
                        "price": normalizePrice(productPrice),
                      });
                    }

                    if (products.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("At least one Fast Food product must be added.")),
                      );
                      return;
                    }

                    newItems = products;
                    normalizedPrice = "Item based";
                  } else {
                    final plainItems = itemsCtrl.text
                        .split(",")
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    if (plainItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Menu content cannot be empty.")),
                      );
                      return;
                    }

                    newItems = plainItems;
                    final rawPrice = priceCtrl.text.trim();
                    normalizedPrice = rawPrice.isEmpty
                        ? ""
                        : rawPrice.startsWith("₺")
                        ? rawPrice
                        : "₺$rawPrice";
                  }

                  final updatedData = Map<String, dynamic>.from(fullCafeteriaData);

                  final mealTypes = (updatedData['mealTypes'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .where((e) =>
                  e != "Lunch" &&
                      e != "Dinner" &&
                      e != "Today's Menu")
                      .toList() ??
                      [];

                  final menus = Map<String, dynamic>.from(
                    (updatedData['menus'] as Map?) ?? {},
                  );

                  menus.remove("Lunch");
                  menus.remove("Dinner");
                  menus.remove("Today's Menu");

                  if (!isEdit && mealTypes.contains(newMealName)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("This category already exists.")),
                    );
                    return;
                  }

                  if (!mealTypes.contains(newMealName)) {
                    mealTypes.add(newMealName);
                  }

                  menus[newMealName] = {
                    "menuName": menuNameCtrl.text.trim().isEmpty
                        ? newMealName
                        : menuNameCtrl.text.trim(),
                    "time": timeCtrl.text.trim(),
                    "price": normalizedPrice,
                    "items": newItems,
                    "isChips": item['isChips'] ?? false,
                  };

                  updatedData['mealTypes'] = mealTypes;
                  updatedData['menus'] = menus;
                  updatedData['updatedAt'] = FieldValue.serverTimestamp();

                  await FirebaseFirestore.instance
                      .collection('settings')
                      .doc('cafeteria')
                      .set(updatedData, SetOptions(merge: true));

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? "Menu updated in Firebase database."
                              : "New menu added to Firebase database.",
                        ),
                      ),
                    );
                    _loadData();
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

}

