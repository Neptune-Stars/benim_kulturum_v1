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
import 'admin_chat_list_screen.dart';


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
  Future<Map<String, int>>? _dashboardSummaryFuture;
  Future<List<Map<String, dynamic>>>? _buildingsFuture;
  Future<Map<String, dynamic>>? _classroomTabDataFuture;
  Future<List<Map<String, dynamic>>>? _instructorsFuture;
  Future<List<Map<String, dynamic>>>? _eventsFuture;
  Future<List<Map<String, dynamic>>>? _announcementsFuture;
  Future<List<Map<String, dynamic>>>? _pricesFuture;
  Future<List<String>>? _priceCategoriesFuture;
  List<String> _currentPriceCategoryOptions = List<String>.from(_priceCategoryOptions);
  Future<List<Map<String, dynamic>>>? _issuesFuture;
  Future<List<Map<String, dynamic>>>? _studentsFuture;
  Future<List<Map<String, dynamic>>>? _weeklyCafeteriaFuture;

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
    _tabController.addListener(() {
      _ensureTabFuture(_tabController.index);
    });
    _ensureTabFuture(0, updateState: false);
  }

  void _refreshWeeklyCafeteriaMenus() {
    _weeklyCafeteriaFuture = DataService.fetchWeeklyCafeteriaMenus(
      weekStart: _cafeteriaWeekStart,
    );
  }

  void _ensureTabFuture(int index, {bool forceRefresh = false, bool updateState = true}) {
    void assignFuture() {
      switch (index) {
        case 0:
          if (forceRefresh || _dashboardSummaryFuture == null) {
            _dashboardSummaryFuture = DataService.fetchDashboardSummary(forceRefresh: forceRefresh);
          }
          break;
        case 1:
          if (forceRefresh || _buildingsFuture == null) {
            _buildingsFuture = DataService.fetchCollection('buildings', forceRefresh: forceRefresh);
          }
          break;
        case 2:
          if (forceRefresh || _classroomTabDataFuture == null) {
            _classroomTabDataFuture = DataService.fetchAdminClassroomTabData(forceRefresh: forceRefresh);
          }
          break;
        case 3:
          if (forceRefresh || _instructorsFuture == null) {
            _instructorsFuture = DataService.fetchCollection('instructors', forceRefresh: forceRefresh);
          }
          break;
        case 4:
          if (forceRefresh || _eventsFuture == null) {
            _eventsFuture = DataService.fetchCollection('events', forceRefresh: forceRefresh);
          }
          break;
        case 5:
          if (forceRefresh || _announcementsFuture == null) {
            _announcementsFuture = DataService.fetchCollection('announcements', forceRefresh: forceRefresh);
          }
          break;
        case 6:
          if (forceRefresh || _weeklyCafeteriaFuture == null) {
            _refreshWeeklyCafeteriaMenus();
          }
          break;
        case 7:
          if (forceRefresh || _pricesFuture == null) {
            _pricesFuture = DataService.fetchCollection('prices', forceRefresh: forceRefresh);
          }
          if (forceRefresh || _priceCategoriesFuture == null) {
            _priceCategoriesFuture = DataService.fetchPriceCategories(forceRefresh: forceRefresh);
          }
          break;
        case 8:
          if (forceRefresh || _issuesFuture == null) {
            _issuesFuture = DataService.fetchCollection('issues', forceRefresh: forceRefresh);
          }
          break;
        case 9:
          if (forceRefresh || _studentsFuture == null) {
            _studentsFuture = DataService.fetchCollection('students', forceRefresh: forceRefresh);
          }
          break;
      }
    }

    if (updateState && mounted) {
      setState(assignFuture);
    } else {
      assignFuture();
    }
  }

  void _refreshTab(int index) {
    _ensureTabFuture(index, forceRefresh: true);
  }

  void _refreshAdminData({String? collectionKey, bool refreshCafeteria = false}) {
    if (refreshCafeteria) {
      DataService.clearCafeteriaCache();
      setState(() {
        _refreshWeeklyCafeteriaMenus();
      });
      return;
    }

    if (collectionKey == null) {
      DataService.clearCache();
      for (int i = 0; i < _tabs.length; i++) {
        _ensureTabFuture(i, forceRefresh: true, updateState: false);
      }
      setState(() {});
      return;
    }

    DataService.clearCollectionCache(collectionKey);

    final tabIndexByCollection = <String, int>{
      'buildings': 1,
      'classrooms': 2,
      'instructors': 3,
      'events': 4,
      'announcements': 5,
      'prices': 7,
      'priceCategories': 7,
      'issues': 8,
      'students': 9,
    };

    final tabIndex = tabIndexByCollection[collectionKey];
    setState(() {
      _dashboardSummaryFuture = DataService.fetchDashboardSummary(forceRefresh: true);
      if (tabIndex != null) {
        _ensureTabFuture(tabIndex, forceRefresh: true, updateState: false);
      }
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

  void _switchTab(int index) {
    _ensureTabFuture(index);
    _tabController.animateTo(index);
  }

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
                  _refreshAdminData(collectionKey: collectionKey);
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
      "Ataköy Campus",
      "İncirli Campus",
      "Şirinevler / Bahçelievler Campus",
      "Basın Ekspres / Küçükçekmece Campus",
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

    if (text.contains("Floor")) return text;

    final number = int.tryParse(text);

    if (number == -1) return "Basement Floor";
    if (number == 0) return "Ground Floor";
    if (number != null) return "${number}th Floor";

    return "Ground Floor";
  }

  int _floorValueFromLabel(String label) {
    if (label == "Basement Floor") return -1;
    if (label == "Ground Floor") return 0;

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
            const Text("Admin Dashboard"),
          ],
        ),
        centerTitle: false,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                tooltip: themeProvider.isDarkMode
                    ? "Switch to light mode"
                    : "Switch to dark mode",
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardSummaryTab(),
          _buildBuildingsTab(),
          _buildClassroomsTab(),
          _buildInstructorsTab(),
          _buildEventsTab(),
          _buildAnnouncementsTab(),
          _buildCafeteriaWeekTab(),
          _buildPricesTab(),
          _buildIssuesFutureTab(),
          _buildStudentsTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardSummaryTab() {
    final future = _dashboardSummaryFuture;
    if (future == null) {
      Future.microtask(() => _ensureTabFuture(0));
      return _buildDashboardSkeleton();
    }

    return FutureBuilder<Map<String, int>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDashboardSkeleton();
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            "Failed to fetch general summary.",
            onRetry: () => _refreshTab(0),
          );
        }

        return _buildGenelTab(snapshot.data ?? <String, int>{});
      },
    );
  }

  Widget _buildBuildingsTab() {
    final future = _buildingsFuture;
    if (future == null) {
      Future.microtask(() => _ensureTabFuture(1));
      return _buildListSkeleton("Loading Campus Units...");
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListSkeleton("Loading Campus Units...");
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            "Failed to fetch Campus Units data.",
            onRetry: () => _refreshTab(1),
          );
        }

        final allUnits = snapshot.data ?? <Map<String, dynamic>>[];
        final sq = _normalizeForSearch(_searchControllers[1]!.text);
        final filteredUnits = allUnits.where((unit) {
          if (sq.isEmpty) return true;
          return _normalizeForSearch(unit['name']?.toString() ?? '').contains(sq) ||
              _normalizeForSearch(unit['location']?.toString() ?? '').contains(sq) ||
              _normalizeForSearch(unit['campus']?.toString() ?? '').contains(sq) ||
              _normalizeForSearch(unit['type']?.toString() ?? '').contains(sq);
        }).toList();

        final campusCards = <Map<String, String>>[
          {'title': 'Ataköy Campus', 'key': 'Ataköy'},
          {'title': 'İncirli Campus', 'key': 'İncirli'},
          {'title': 'Basın Ekspres Campus', 'key': 'Basın Ekspres'},
          {'title': 'Şirinevler Campus', 'key': 'Şirinevler'},
        ];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Campus Units (${filteredUnits.length})",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openBuildingForm(isEdit: false),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AppSearchBar(
                controller: _searchControllers[1]!,
                placeholder: "Search unit or campus...",
                onChanged: (val) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: campusCards.length,
                itemBuilder: (context, index) {
                  final campus = campusCards[index];
                  final campusKey = campus['key']!;
                  final campusTitle = campus['title']!;
                  final unitsForCampus = filteredUnits.where((unit) {
                    return _unitCampusKey(unit) == campusKey;
                  }).toList()
                    ..sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

                  return _buildCampusUnitCard(
                    title: campusTitle,
                    campusKey: campusKey,
                    units: unitsForCampus,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _unitCampusKey(Map<dynamic, dynamic> unit) {
    final explicitCampus = unit['campus']?.toString() ?? '';
    if (explicitCampus.trim().isNotEmpty) {
      return _matchCampusKey(explicitCampus);
    }

    final location = unit['location']?.toString() ?? '';
    if (location.trim().isNotEmpty) {
      final firstPart = location.split(',').first.trim();
      return _matchCampusKey(firstPart);
    }

    final building = unit['building']?.toString() ?? '';
    if (building.trim().isNotEmpty) {
      final firstPart = building.split(',').first.trim();
      return _matchCampusKey(firstPart);
    }

    return 'Ataköy';
  }

  String _matchCampusKey(String rawCampus) {
    final value = rawCampus.toLowerCase().trim();

    if (value.contains('atak')) return 'Ataköy';
    if (value.contains('incir') || value.contains('ıncir') || value.contains('i̇ncir')) return 'İncirli';
    if (value.contains('bas') || value.contains('baş') || value.contains('ekspres') || value.contains('küçük') || value.contains('kucuk')) {
      return 'Basın Ekspres';
    }
    if (value.contains('sirin') || value.contains('şirin') || value.contains('bahcel') || value.contains('bahçel')) {
      return 'Şirinevler';
    }

    return 'Ataköy';
  }

  Widget _buildCampusUnitCard({
    required String title,
    required String campusKey,
    required List<Map<String, dynamic>> units,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _adminBorderColor()),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _adminPrimaryColor().withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.location_city_outlined,
            color: _adminPrimaryColor(),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: _adminTextPrimaryColor(),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "${units.length} unit(s)",
          style: TextStyle(
            color: _adminTextMutedColor(),
            fontSize: 13,
          ),
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          children: [
            IconButton(
              tooltip: "Add unit to $title",
              onPressed: () => _openBuildingForm(
                isEdit: false,
                defaultCampus: campusKey,
              ),
              icon: Icon(
                Icons.add_circle_outline,
                color: _adminPrimaryColor(),
              ),
            ),
            Icon(
              Icons.expand_more,
              color: _adminTextMutedColor(),
            ),
          ],
        ),
        children: [
          if (units.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorderColor : AppTheme.backgroundColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "No units added for this campus yet.",
                style: TextStyle(color: _adminTextMutedColor()),
              ),
            )
          else
            ...units.map((unit) {
              return Column(
                children: [
                  _buildListItem(
                    unit['name']?.toString() ?? 'Unnamed unit',
                    "${unit['type']?.toString() ?? 'Unit'} • ${unit['location']?.toString() ?? campusKey}",
                        () => _openBuildingForm(isEdit: true, item: unit),
                        () => _showDeleteDialog(
                      'buildings',
                      (unit['firestoreDocId'] ?? unit['id']).toString(),
                    ),
                  ),
                  if (unit != units.last) const Divider(height: 18),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildClassroomsTab() {
    final future = _classroomTabDataFuture;
    if (future == null) {
      Future.microtask(() => _ensureTabFuture(2));
      return _buildListSkeleton("Loading classrooms...");
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListSkeleton("Loading classrooms...");
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            "Failed to fetch classroom data.",
            onRetry: () => _refreshTab(2),
          );
        }

        final data = snapshot.data ?? {};
        final allClassrooms = data['classrooms'] as List<dynamic>? ?? [];
        final campusOptions = _getCampusOptions(data);
        final classroomLocationsByCampus = _getClassroomLocationsByCampus(data);

        final sq = _normalizeForSearch(_searchControllers[2]!.text);
        final filteredClassrooms = allClassrooms.where((c) {
          return _normalizeForSearch(c['name']?.toString() ?? '').contains(sq) ||
              _normalizeForSearch(c['building']?.toString() ?? '').contains(sq) ||
              _normalizeForSearch(c['campus']?.toString() ?? '').contains(sq) ||
              _normalizeForSearch(c['location']?.toString() ?? '').contains(sq);
        }).toList();

        return _buildManagementTab(
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
                  () => _showDeleteDialog('classrooms', (e['firestoreDocId'] ?? e['id']).toString()),
            );
          }).toList(),
          onAdd: () => _openClassroomForm(
            isEdit: false,
            campusOptions: campusOptions,
            locationsByCampus: classroomLocationsByCampus,
          ),
        );
      },
    );
  }

  Widget _buildInstructorsTab() {
    return _buildCollectionFutureTab(
      future: _instructorsFuture,
      tabIndex: 3,
      title: "Instructors",
      searchController: _searchControllers[3]!,
      searchFields: const ['name', 'department'],
      onAdd: () => _openInstructorForm(isEdit: false),
      itemBuilder: (e) => _buildListItem(
        e['name'] ?? '',
        e['department'] ?? '',
            () => _openInstructorForm(isEdit: true, item: e),
            () => _showDeleteDialog('instructors', (e['firestoreDocId'] ?? e['id']).toString()),
      ),
    );
  }

  Widget _buildEventsTab() {
    return _buildCollectionFutureTab(
      future: _eventsFuture,
      tabIndex: 4,
      title: "Events",
      searchController: _searchControllers[4]!,
      searchFields: const ['title', 'date', 'location'],
      onAdd: () => _openEventForm(isEdit: false),
      itemBuilder: (e) => _buildListItem(
        e['title'] ?? '',
        "${e['date'] ?? '-'} - ${e['location'] ?? '-'}",
            () => _openEventForm(isEdit: true, item: e),
            () => _showDeleteDialog('events', (e['firestoreDocId'] ?? e['id']).toString()),
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    return _buildCollectionFutureTab(
      future: _announcementsFuture,
      tabIndex: 5,
      title: "Announcements",
      searchController: _searchControllers[5]!,
      searchFields: const ['title', 'date'],
      onAdd: () => _openAnnouncementForm(isEdit: false),
      itemBuilder: (e) => _buildListItem(
        e['title'] ?? '',
        e['date'] ?? '',
            () => _openAnnouncementForm(isEdit: true, item: e),
            () => _showDeleteDialog('announcements', (e['firestoreDocId'] ?? e['id']).toString()),
      ),
    );
  }

  static const List<String> _priceCategoryOptions = [
    "Beverages",
    "Coffee Varieties",
    "Toast Varieties",
    "Snacks",
  ];

  List<String> _mergePriceCategories(
      List<String> storedCategories,
      List<Map<String, dynamic>> prices,
      ) {
    final result = <String>[];

    void addCategory(String? value) {
      final category = value?.trim();
      if (category == null || category.isEmpty) return;
      if (!result.contains(category)) {
        result.add(category);
      }
    }

    for (final category in _priceCategoryOptions) {
      addCategory(category);
    }
    for (final category in storedCategories) {
      addCategory(category);
    }
    for (final price in prices) {
      addCategory(_inferPriceCategory(
        price['category']?.toString(),
        price['name']?.toString() ?? '',
      ));
    }

    return result;
  }

  String _normalizePriceValue(String rawPrice) {
    final value = rawPrice.trim();
    if (value.isEmpty) return "₺0";
    return value.startsWith("₺") ? value : "₺$value";
  }

  String _inferPriceCategory(String? rawCategory, String productName) {
    final raw = rawCategory?.trim() ?? "";
    final name = productName.toLowerCase();

    if (_priceCategoryOptions.contains(raw)) {
      return raw;
    }

    if (name.contains("kahve") ||
        name.contains("latte") ||
        name.contains("espresso") ||
        name.contains("americano") ||
        name.contains("cappuccino") ||
        name.contains("mocha") ||
        name.contains("filtre")) {
      return "Coffee Varieties";
    }

    if (name.contains("tost") ||
        name.contains("sandviç") ||
        name.contains("sandwich")) {
      return "Toast Varieties";
    }

    if (name.contains("eti") ||
        name.contains("puf") ||
        name.contains("çikolata") ||
        name.contains("bisküvi") ||
        name.contains("cips") ||
        name.contains("kraker") ||
        name.contains("gofret") ||
        name.contains("kek")) {
      return "Snacks";
    }

    if (name.contains("çay") ||
        name.contains("su") ||
        name.contains("ayran") ||
        name.contains("kola") ||
        name.contains("soda") ||
        name.contains("meyve suyu") ||
        name.contains("ice tea") ||
        name.contains("fanta") ||
        name.contains("sprite")) {
      return "Beverages";
    }

    if (raw == "Çay/Kahve") {
      return name.contains("kahve") ? "Coffee Varieties" : "Beverages";
    }
    if (raw == "Atıştırmalık" || raw == "Atıştırmalıklar" || raw == "Abur Cubur") {
      return "Snacks";
    }
    if (raw == "Yemek") {
      return "Toast Varieties";
    }

    // Custom categories created by the admin must be preserved.
    if (raw.isNotEmpty) {
      return raw;
    }

    return "Beverages";
  }

  String _priceDocumentId(Map<dynamic, dynamic>? item) {
    final firestoreDocId = item?['firestoreDocId']?.toString().trim();
    if (firestoreDocId != null && firestoreDocId.isNotEmpty && firestoreDocId != "null") {
      return firestoreDocId;
    }

    final id = item?['id']?.toString().trim();
    if (id != null && id.isNotEmpty && id != "null") {
      return id;
    }

    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  bool _isDefaultPriceCategory(String category) {
    return _priceCategoryOptions.contains(category.trim());
  }

  Widget _buildPricesTab() {
    final pricesFuture = _pricesFuture;
    final categoriesFuture = _priceCategoriesFuture;
    if (pricesFuture == null || categoriesFuture == null) {
      Future.microtask(() => _ensureTabFuture(7));
      return _buildListSkeleton("Loading prices...");
    }

    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([pricesFuture, categoriesFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListSkeleton("Loading prices...");
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            "Failed to fetch price data.",
            onRetry: () => _refreshTab(7),
          );
        }

        final rawPrices = snapshot.data?[0];
        final allPrices = rawPrices is List
            ? rawPrices
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList()
            : <Map<String, dynamic>>[];

        final rawCategories = snapshot.data?[1];
        final storedCategories = rawCategories is List
            ? rawCategories.map((category) => category.toString()).toList()
            : <String>[];
        final categoryOptions = _mergePriceCategories(storedCategories, allPrices);
        _currentPriceCategoryOptions = categoryOptions;

        final sq = _normalizeForSearch(_searchControllers[7]!.text);

        final groupedPrices = <String, List<Map<String, dynamic>>>{
          for (final category in categoryOptions) category: <Map<String, dynamic>>[],
        };

        for (final priceItem in allPrices) {
          final normalizedItem = Map<String, dynamic>.from(priceItem);
          final normalizedCategory = _inferPriceCategory(
            normalizedItem['category']?.toString(),
            normalizedItem['name']?.toString() ?? "",
          );
          normalizedItem['category'] = normalizedCategory;

          final searchableText = [
            normalizedItem['name']?.toString() ?? "",
            normalizedItem['price']?.toString() ?? "",
            normalizedCategory,
          ].map(_normalizeForSearch).join(" ");

          if (sq.isNotEmpty && !searchableText.contains(sq)) {
            continue;
          }

          groupedPrices.putIfAbsent(normalizedCategory, () => <Map<String, dynamic>>[]);
          groupedPrices[normalizedCategory]!.add(normalizedItem);
        }

        final visibleCount = groupedPrices.values.fold<int>(0, (sum, items) => sum + items.length);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Prices ($visibleCount)",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openPriceCategoryForm,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add Category"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AppSearchBar(
                controller: _searchControllers[7]!,
                placeholder: "Search product, price, or category...",
                onChanged: (val) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: categoryOptions.length,
                itemBuilder: (context, index) {
                  final category = categoryOptions[index];
                  final items = groupedPrices[category] ?? <Map<String, dynamic>>[];
                  return _buildPriceCategoryTile(category, items, searchActive: sq.isNotEmpty);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriceCategoryTile(
      String category,
      List<Map<String, dynamic>> items, {
        required bool searchActive,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _adminBorderColor()),
      ),
      child: ExpansionTile(
        initiallyExpanded: searchActive,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          category,
          style: TextStyle(
            color: _adminTextPrimaryColor(),
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          "${items.length} products",
          style: TextStyle(color: _adminTextMutedColor()),
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            IconButton(
              tooltip: "Add product to $category",
              icon: const Icon(Icons.add_circle_outline),
              color: _adminPrimaryColor(),
              onPressed: () => _openPriceForm(
                isEdit: false,
                defaultCategory: category,
              ),
            ),
            if (!_isDefaultPriceCategory(category))
              IconButton(
                tooltip: "Delete category",
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.destructiveColor,
                onPressed: () => _openDeletePriceCategoryDialog(category, items),
              ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "No products in this category.",
                  style: TextStyle(color: _adminTextMutedColor()),
                ),
              ),
            )
          else
            ...items.map((item) {
              return Column(
                children: [
                  _buildListItem(
                    item['name']?.toString() ?? "Unnamed product",
                    "${item['price'] ?? '-'} • ${item['category'] ?? category}",
                        () => _openPriceForm(isEdit: true, item: item),
                        () => _showDeleteDialog('prices', _priceDocumentId(item)),
                  ),
                  if (item != items.last) const Divider(height: 18),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildIssuesFutureTab() {
    final future = _issuesFuture;
    if (future == null) {
      Future.microtask(() => _ensureTabFuture(8));
      return _buildListSkeleton("Loading issues...");
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListSkeleton("Loading issues...");
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            "Failed to fetch issue records.",
            onRetry: () => _refreshTab(8),
          );
        }

        final allIssues = snapshot.data ?? [];
        final sq = _normalizeForSearch(_searchControllers[8]!.text);
        final filteredIssues = allIssues.where((iss) {
          return _normalizeForSearch(iss['subject']?.toString() ?? '').contains(sq) ||
              _normalizeForSearch(iss['category']?.toString() ?? '').contains(sq);
        }).toList();

        return _buildIssuesTab(filteredIssues, _searchControllers[8]!);
      },
    );
  }

  Widget _buildStudentsTab() {
    return _buildCollectionFutureTab(
      future: _studentsFuture,
      tabIndex: 9,
      title: "Students",
      searchController: _searchControllers[9]!,
      searchFields: const ['name', 'no', 'email'],
      onAdd: () => _openStudentForm(isEdit: false),
      itemBuilder: (s) => _buildListItem(
        s['name'] ?? '',
        "${s['no'] ?? '-'} - ${s['grade'] ?? '-'}",
            () => _openStudentForm(isEdit: true, item: s),
            () => _showDeleteDialog('students', (s['firestoreDocId'] ?? s['id']).toString()),
      ),
    );
  }

  Widget _buildCollectionFutureTab({
    required Future<List<Map<String, dynamic>>>? future,
    required int tabIndex,
    required String title,
    required TextEditingController searchController,
    required List<String> searchFields,
    required VoidCallback onAdd,
    required Widget Function(Map<String, dynamic> item) itemBuilder,
  }) {
    if (future == null) {
      Future.microtask(() => _ensureTabFuture(tabIndex));
      return _buildListSkeleton("Loading $title...");
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListSkeleton("Loading $title...");
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            "Failed to fetch $title data.",
            onRetry: () => _refreshTab(tabIndex),
          );
        }

        final allItems = snapshot.data ?? [];
        final sq = _normalizeForSearch(searchController.text);
        final filteredItems = allItems.where((item) {
          if (sq.isEmpty) return true;
          return searchFields.any((field) {
            return _normalizeForSearch(item[field]?.toString() ?? '').contains(sq);
          });
        }).toList();

        return _buildManagementTab(
          title: title,
          count: filteredItems.length,
          searchController: searchController,
          items: filteredItems.map(itemBuilder).toList(),
          onAdd: onAdd,
        );
      },
    );
  }

  Widget _buildDashboardSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonBox(height: 54, borderRadius: 12),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 720 ? 3 : 2;
              final aspectRatio = width < 380 ? 1.08 : 1.22;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => _buildSkeletonBox(borderRadius: 12),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListSkeleton(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 76, height: 34, child: _buildSkeletonBox(borderRadius: 8)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSkeletonBox(height: 46, borderRadius: 10),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 7,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonBox(height: 16, width: 180, borderRadius: 6),
                          const SizedBox(height: 8),
                          _buildSkeletonBox(height: 13, width: 240, borderRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildSkeletonBox(height: 32, width: 32, borderRadius: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonBox({double? width, double? height, double borderRadius = 8}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildErrorState(String message, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 44, color: _adminTextMutedColor()),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: _adminTextPrimaryColor()),
            ),
            const SizedBox(height: 8),
            Text(
              "Check your connection and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: _adminTextMutedColor()),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Try again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCafeteriaWeekTab() {
    if (_weeklyCafeteriaFuture == null) {
      Future.microtask(() => _ensureTabFuture(6));
      return _buildListSkeleton("Loading cafeteria menus...");
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _weeklyCafeteriaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListSkeleton("Loading cafeteria menus...");
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text("Failed to fetch weekly cafeteria data."),
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
                            _refreshWeeklyCafeteriaMenus();
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
                            _refreshWeeklyCafeteriaMenus();
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
                    "If you disable the day tick, students will see no food for that day. When the day is active, you can edit Breakfast, Meal, and Fast Food contents for that day.",
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
              tooltip: isDayActive ? "Edit day" : "Day closed",
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
                ? "${DataService.weekdayName(date.weekday)} opened to students again."
                : "${DataService.weekdayName(date.weekday)} closed for students.",
          ),
        ),
      );
      setState(() {
        _refreshWeeklyCafeteriaMenus();
      });
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
                ? "$mealType made visible to students."
                : "$mealType hidden from students.",
          ),
        ),
      );
      onSaved?.call();
      setState(() {
        _refreshWeeklyCafeteriaMenus();
      });
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
                            "If you re-enable the day tick, students can see this day and menus can be edited again.",
                            style: TextStyle(color: _adminTextMutedColor(), height: 1.35),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await DataService.setCafeteriaDayActiveStatus(date, true);
                              setDialogState(() {});
                              setState(() {
                                _refreshWeeklyCafeteriaMenus();
                              });
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
                                            setState(() {
                                              _refreshWeeklyCafeteriaMenus();
                                            });
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
                                            setState(() {
                                              _refreshWeeklyCafeteriaMenus();
                                            });
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
                      hintText: "e.g. Today's Meal",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Time Range",
                      hintText: "e.g. 13:00-18:00",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    decoration: InputDecoration(
                      labelText: isFastFood ? "General Price Info" : "Price",
                      hintText: isFastFood ? "Product based" : "e.g. ₺35",
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
                        "Fast Food Products",
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
                                  labelText: "Product ${index + 1}",
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
                        label: const Text("Add Product"),
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
                      ? (rawPrice.isEmpty ? "Product based" : rawPrice)
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
                    "isActiveManuallyEdited": item['isActiveManuallyEdited'] == true,
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
                    setState(() {
                      _refreshWeeklyCafeteriaMenus();
                    });
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

  Widget _buildGenelTab(Map<String, int> summary) {
    final bCount = summary['buildings'] ?? 0;
    final cCount = summary['classrooms'] ?? 0;
    final iCount = summary['instructors'] ?? 0;
    final eCount = summary['events'] ?? 0;
    final announcementCount = summary['announcements'] ?? 0;
    final cafeteriaCount = summary['cafeteriaMenus'] ?? 0;
    final priceCount = summary['prices'] ?? 0;
    final issueCount = summary['issues'] ?? 0;
    final studentCount = summary['students'] ?? 0;

    return RefreshIndicator(
      onRefresh: () async => _refreshTab(0),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_done, color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Google Firebase Cloud Active",
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.88,
              children: [
                _buildStatCard(Icons.business, "Units", bCount.toString(), 1),
                _buildStatCard(Icons.meeting_room, "Classrooms", cCount.toString(), 2),
                _buildStatCard(Icons.people, "Instructors", iCount.toString(), 3),
                _buildStatCard(Icons.event, "Events", eCount.toString(), 4),
                _buildStatCard(Icons.campaign, "Announcements", announcementCount.toString(), 5),
                _buildStatCard(Icons.restaurant_menu, "Cafeteria", cafeteriaCount.toString(), 6),
                _buildStatCard(Icons.attach_money, "Prices", priceCount.toString(), 7),
                _buildStatCard(Icons.report_problem, "Issues", issueCount.toString(), 8),
                _buildStatCard(Icons.person, "Students", studentCount.toString(), 9),
              ],
            ),
            const SizedBox(height: 12),
            _buildSupportShortcutTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportShortcutTile() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminChatListScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _adminBorderColor()),
        ),
        child: Row(
          children: [
            Icon(
              Icons.support_agent,
              color: _adminPrimaryColor(),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Live Support Messages",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _adminTextPrimaryColor(),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _adminTextMutedColor(),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, int tabIndex) {
    return InkWell(
      onTap: () => _switchTab(tabIndex),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _adminBorderColor()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: _adminPrimaryColor(),
                  size: 18,
                ),
                Icon(
                  Icons.chevron_right,
                  color: _adminTextMutedColor(),
                  size: 16,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _adminTextPrimaryColor(),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _adminTextMutedColor(),
                    fontSize: 11.5,
                    height: 1.15,
                  ),
                ),
              ],
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
                "Incoming Issues (${issues.length})",
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
                _refreshAdminData(collectionKey: 'issues');
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

    final List<String> gradeOptions = ["Prep", "1st Grade", "2nd Grade", "3rd Grade", "4th Grade", "Graduated"];
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
                    _buildTextField("Student ID", isNumber: true, controller: noCtrl),
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
                      if (context.mounted) { Navigator.pop(context); _refreshAdminData(collectionKey: 'students'); }
                    },
                    child: const Text("Save")
                )
              ],
            );
          }
      ),
    );
  }

  void _openDeletePriceCategoryDialog(
      String category,
      List<Map<String, dynamic>> items,
      ) {
    if (_isDefaultPriceCategory(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Default categories cannot be deleted.")),
      );
      return;
    }

    if (items.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            "Category cannot be deleted",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "'$category' contains ${items.length} product(s). Delete or move the products in this category first.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          "Delete Category",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete '$category'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await DataService.deletePriceCategory(category);

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("'$category' category deleted.")),
              );
              _refreshAdminData(collectionKey: 'priceCategories');
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: AppTheme.destructiveColor),
            ),
          ),
        ],
      ),
    );
  }

  void _openPriceCategoryForm() {
    final categoryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          "Add New Category",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: _buildTextField(
          "Category Name",
          controller: categoryCtrl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final categoryName = categoryCtrl.text.trim();
              if (categoryName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Category name cannot be empty.")),
                );
                return;
              }

              await DataService.addPriceCategory(categoryName);

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              _refreshAdminData(collectionKey: 'priceCategories');
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _openPriceForm({
    required bool isEdit,
    Map<dynamic, dynamic>? item,
    String? defaultCategory,
  }) {
    final nameCtrl = TextEditingController(text: item?['name']?.toString() ?? "");
    final priceCtrl = TextEditingController(
      text: item?['price']?.toString().replaceAll("₺", "") ?? "",
    );

    String? selectedCat = isEdit
        ? _inferPriceCategory(item?['category']?.toString(), item?['name']?.toString() ?? "")
        : (defaultCategory ?? "Beverages");

    final formCategories = <String>[];
    void addFormCategory(String? category) {
      final value = category?.trim();
      if (value == null || value.isEmpty) return;
      if (!formCategories.contains(value)) {
        formCategories.add(value);
      }
    }
    for (final category in _currentPriceCategoryOptions) {
      addFormCategory(category);
    }
    addFormCategory(selectedCat);
    if (formCategories.isEmpty) {
      formCategories.addAll(_priceCategoryOptions);
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(
              isEdit ? "Edit — Price" : "Add New Price",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDropdown(
                    "Category",
                    formCategories,
                    value: formCategories.contains(selectedCat) ? selectedCat : formCategories.first,
                    onChanged: (val) => setDialogState(() => selectedCat = val),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField("Product Name", controller: nameCtrl),
                  const SizedBox(height: 12),
                  _buildTextField("Price", isNumber: true, controller: priceCtrl),
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
                  final productName = nameCtrl.text.trim();
                  if (productName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Product name cannot be empty.")),
                    );
                    return;
                  }

                  final docId = isEdit
                      ? _priceDocumentId(item)
                      : DateTime.now().millisecondsSinceEpoch.toString();

                  final parsedNumericId = int.tryParse(docId);
                  final idValue = item?['id'] ?? parsedNumericId ?? docId;

                  final newData = <String, dynamic>{
                    'id': idValue,
                    'name': productName,
                    'price': _normalizePriceValue(priceCtrl.text),
                    'category': selectedCat ?? "Beverages",
                  };

                  await FirebaseFirestore.instance.collection('prices').doc(docId).set(newData);

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _refreshAdminData(collectionKey: 'prices');
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openBuildingForm({required bool isEdit, Map<dynamic, dynamic>? item, String? defaultCampus}) {
    final nameCtrl = TextEditingController(text: item?['name']?.toString() ?? '');
    final locationCtrl = TextEditingController(
      text: item?['location']?.toString() ?? (defaultCampus == null ? '' : '$defaultCampus Campus'),
    );

    final List<String> campusOptions = ["Ataköy", "İncirli", "Basın Ekspres", "Şirinevler"];
    final List<String> unitTypeOptions = [
      "Academic Unit",
      "Classroom",
      "Laboratory",
      "Library",
      "Hall",
      "Auditorium",
      "Health Unit",
      "Food & Drink",
      "Student Services",
      "Security",
      "Service",
      "Office",
      "Workshop",
    ];

    String? _matchCampusOption(String? rawValue) {
      if (rawValue == null) return null;
      final value = rawValue.toLowerCase().trim();
      if (value.isEmpty) return null;

      if (value.contains('atak')) return "Ataköy";
      if (value.contains('incir') || value.contains('ıncir') || value.contains('i̇ncir')) return "İncirli";
      if (value.contains('bas') || value.contains('baş') || value.contains('ekspres') || value.contains('küçük') || value.contains('kucuk')) return "Basın Ekspres";
      if (value.contains('sirin') || value.contains('şirin') || value.contains('bahcel') || value.contains('bahçel')) return "Şirinevler";
      return null;
    }

    String _normalizeUnitType(String? rawValue) {
      final value = (rawValue ?? '')
          .trim()
          .toLowerCase()
          .replaceAll('_', ' ')
          .replaceAll('-', ' ');

      if (value.isEmpty) return "Academic Unit";
      if (value.contains('faculty') || value.contains('school') || value.contains('department') || value.contains('academic unit')) {
        return "Academic Unit";
      }
      if (value.contains('classroom') || value.contains('lecture')) return "Classroom";
      if (value.contains('laboratory') || value.contains('lab')) return "Laboratory";
      if (value.contains('library')) return "Library";
      if (value.contains('auditorium')) return "Auditorium";
      if (value.contains('hall') || value.contains('courtroom')) return "Hall";
      if (value.contains('health') || value.contains('infirmary') || value.contains('revir')) return "Health Unit";
      if (value.contains('cafe') || value.contains('restaurant') || value.contains('canteen') || value.contains('food')) return "Food & Drink";
      if (value.contains('student service') || value.contains('student_services')) return "Student Services";
      if (value.contains('security')) return "Security";
      if (value.contains('office')) return "Office";
      if (value.contains('workshop') || value.contains('factory')) return "Workshop";
      if (value.contains('service') || value.contains('bank') || value.contains('stationery') || value.contains('hairdresser')) return "Service";

      return "Academic Unit";
    }

    String? selectedCampus = defaultCampus != null && campusOptions.contains(defaultCampus)
        ? defaultCampus
        : _matchCampusOption(item?['campus']?.toString()) ?? _matchCampusOption(item?['location']?.toString());

    selectedCampus ??= campusOptions.first;

    String selectedType = _normalizeUnitType(item?['type']?.toString());
    if (!unitTypeOptions.contains(selectedType)) {
      selectedType = "Academic Unit";
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEdit ? "Edit: Unit/Area" : "Add New Unit",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Unit Name"),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    "Campus",
                    campusOptions,
                    value: selectedCampus,
                    onChanged: (val) => setDialogState(() => selectedCampus = val),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    "Unit Category",
                    unitTypeOptions,
                    value: unitTypeOptions.contains(selectedType) ? selectedType : "Academic Unit",
                    onChanged: (val) => setDialogState(() => selectedType = val ?? "Academic Unit"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Location Detail",
                      hintText: "Example: Ataköy Campus, Main Building, 4th Floor, Room 4G09",
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
                  final name = nameCtrl.text.trim();
                  final location = locationCtrl.text.trim();

                  if (name.isEmpty || selectedCampus == null || location.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill in the unit name, campus, and location fields.")),
                    );
                    return;
                  }

                  final docId = isEdit
                      ? (item!['firestoreDocId'] ?? item['id']).toString()
                      : DateTime.now().millisecondsSinceEpoch.toString();

                  final parsedNumericId = int.tryParse(docId);
                  final idValue = item?['id'] ?? parsedNumericId ?? docId;

                  final newData = <String, dynamic>{
                    'id': idValue,
                    'name': name,
                    'campus': selectedCampus,
                    'location': location,
                    'abbr': item?['abbr'] ?? 'NEW',
                    'type': selectedType,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  await FirebaseFirestore.instance
                      .collection('buildings')
                      .doc(docId)
                      .set(newData, SetOptions(merge: true));

                  if (context.mounted) {
                    Navigator.pop(context);
                    _refreshAdminData(collectionKey: 'buildings');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Unit saved to Firebase database.")),
                    );
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

  void _openClassroomForm({
    required bool isEdit,
    Map<dynamic, dynamic>? item,
    required List<String> campusOptions,
    required Map<String, List<String>> locationsByCampus,
  }) {
    final nameCtrl = TextEditingController(text: item?['name']?.toString() ?? '');
    final capacityCtrl = TextEditingController(text: (item?['capacity'] ?? 40).toString());

    final List<String> floorOptions = [
      "Basement Floor",
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
                      const SnackBar(content: Text("Please fill in the classroom name, campus, location, floor, and type fields.")),
                    );
                    return;
                  }

                  final int docId = isEdit
                      ? int.tryParse(item!['id'].toString()) ?? DateTime.now().millisecondsSinceEpoch
                      : DateTime.now().millisecondsSinceEpoch;

                  final Map<String, dynamic> newData = {
                    'id': docId,
                    'name': name,

                    // New clean Firebase fields
                    'campus': selectedCampus,
                    'location': selectedLocation,
                    'floor': _floorValueFromLabel(selectedFloor!),
                    'floorLabel': selectedFloor,

                    // Kept for old screens/detail pages that still read "building"
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
                    _refreshAdminData(collectionKey: 'classrooms');
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
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Instructor Full Name")),
              const SizedBox(height: 12),
              TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: "Department")),
              const SizedBox(height: 12),
              TextField(
                  controller: officeHoursCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: "Office Hours",
                      hintText: "e.g. Mon 10:00-12:00, Tue 14:00-16:00",
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
                  'email': item?['email'] ?? 'iletisim@uni.edu.tr'
                };

                await FirebaseFirestore.instance.collection('instructors').doc(docId).set(newData);

                if (context.mounted) {
                  Navigator.pop(context);
                  _refreshAdminData(collectionKey: 'instructors');
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
      "Culture & Art",
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
                      hintText: "e.g. April 28",
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Time",
                      hintText: "e.g. 14:00",
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: locCtrl,
                    decoration: const InputDecoration(
                      labelText: "Location",
                      hintText: "e.g. Ataköy Campus / Conference Hall",
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
                      hintText: "Enter a short description about the event.",
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
                        content: Text("Title, date, and location fields are required."),
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
                        ? 'No details provided.'
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
                    _refreshAdminData(collectionKey: 'events');
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
                      labelText: "Display Date",
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
                      labelText: "Display Time",
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
                        content: Text("Title, content, display date, and time are required."),
                      ),
                    );
                    return;
                  }

                  final publishDateTime = _tryBuildPublishDateTime(publishDate, publishTime);

                  if (publishDateTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Date must be DD/MM/YYYY and time HH:MM format. e.g., 28/04/2026 and 13:45"),
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

                    // Display/scheduling fields
                    'date': publishDate,
                    'publishDate': publishDate,
                    'publishTime': publishTime,
                    'publishAt': Timestamp.fromDate(publishDateTime),

                    // UI fields
                    'isNew': true,

                    // Audit fields
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
                    _refreshAdminData(collectionKey: 'announcements');
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
          (mealName == "Meal"
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
      if (trimmed == "Product based") return trimmed;
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
                        hintText: "e.g. Breakfast, Meal, Fast Food",
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: menuNameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Menu Name",
                      hintText: "e.g. Today's Meal",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Time Range",
                      hintText: "e.g. 13:00-18:00",
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
                        "Fast Food products are priced per item.",
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
                                  hintText: "e.g. Toast",
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
                        hintText: "e.g. ₺35",
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
                      newMealName == "Menu of the Day") {
                    newMealName = "Meal";
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
                    normalizedPrice = "Product based";
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
                      e != "Menu of the Day")
                      .toList() ??
                      [];

                  final menus = Map<String, dynamic>.from(
                    (updatedData['menus'] as Map?) ?? {},
                  );

                  menus.remove("Lunch");
                  menus.remove("Dinner");
                  menus.remove("Menu of the Day");

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
                    _refreshAdminData(refreshCafeteria: true);
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