import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../data/data_service.dart';
import '../widgets/search_bar_widget.dart';
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
  String _issueStatusFilter = 'all'; // all, open, resolved
  String _issuePriorityFilter = 'all'; // all, normal, medium, high

  static const String _instructorFilterAll = 'All';
  String _instructorDepartmentFilter = _instructorFilterAll;
  String _instructorDayFilter = _instructorFilterAll;

  static const String _announcementFilterAll = 'All';
  String _announcementCategoryFilter = _announcementFilterAll;

  static const String _classroomFilterAll = 'All';
  String _classroomCampusFilter = _classroomFilterAll;
  String _classroomLocationFilter = _classroomFilterAll;
  String _classroomFloorFilter = _classroomFilterAll;
  String _classroomTypeFilter = _classroomFilterAll;

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
            _issuesFuture = DataService.fetchCollection(
              'issues',
              forceRefresh: forceRefresh,
              orderBy: 'createdAt',
              descending: true,
            );
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
    final isAnnouncementDelete = collectionKey == 'announcements';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isAnnouncementDelete ? "Delete Announcement" : "Confirm Deletion",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isAnnouncementDelete
              ? "Are you sure you want to delete this announcement? It will be removed from Firestore and will no longer appear on student screens."
              : "Are you sure you want to delete this record? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (isAnnouncementDelete) {
                  await DataService.deleteAnnouncement(docId);
                } else {
                  await FirebaseFirestore.instance
                      .collection(collectionKey)
                      .doc(docId)
                      .delete();

                  DataService.clearCollectionCache(collectionKey);
                }

                if (context.mounted) {
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAnnouncementDelete
                            ? "Announcement deleted from Firebase and student screens."
                            : "Record deleted from cloud database.",
                      ),
                    ),
                  );

                  _refreshAdminData(collectionKey: collectionKey);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAnnouncementDelete
                            ? "Announcement could not be deleted: $e"
                            : "Record could not be deleted: $e",
                      ),
                      backgroundColor: AppTheme.destructiveColor,
                    ),
                  );
                }
              }
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

    if (number == -2) return "B2 Floor";
    if (number == -1) return "B1 Floor";
    if (number == 0) return "Ground Floor";
    if (number != null) return "${number}th Floor";

    return "Ground Floor";
  }

  int _floorValueFromLabel(String label) {
    if (label == "B2 Floor") return -2;
    if (label == "B1 Floor" || label == "Basement Floor") return -1;
    if (label == "Ground Floor") return 0;

    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match == null) return 0;

    return int.tryParse(match.group(1) ?? "0") ?? 0;
  }

  String _normalizeClassroomType(dynamic rawType) {
    final value = _normalizeForSearch(rawType?.toString() ?? '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    if (value.contains('laboratory') || value == 'lab' || value.contains(' lab')) {
      return "Laboratory";
    }

    if (value.contains('amphitheater') ||
        value.contains('amfitheater') ||
        value.contains('amfi') ||
        value.contains('auditorium')) {
      return "Amphitheater";
    }

    if (value.contains('classroom') ||
        value.contains('lecture') ||
        value.contains('derslik') ||
        value.contains('sinif') ||
        value.contains('sınıf')) {
      return "Classroom";
    }

    return rawType?.toString().trim().isNotEmpty == true
        ? rawType.toString().trim()
        : "Classroom";
  }

  bool _isClassroomEducationSpace(Map<dynamic, dynamic> classroom) {
    final type = _normalizeClassroomType(classroom['type']);
    final searchableText = [
      classroom['name'],
      classroom['type'],
      classroom['category'],
      classroom['location'],
      classroom['building'],
    ].map((value) => _normalizeForSearch(value?.toString() ?? '')).join(' ');

    final blockedKeywords = <String>[
      'library',
      'kutuphane',
      'canteen',
      'kantin',
      'cafeteria',
      'cafe',
      'health unit',
      'revir',
      'infirmary',
      'student affairs',
      'student services',
      'security',
      'office',
      'food',
      'restaurant',
    ];

    final isBlockedFacility = blockedKeywords.any(searchableText.contains);
    return <String>{"Classroom", "Amphitheater", "Laboratory"}.contains(type) &&
        !isBlockedFacility;
  }

  String _bestMatchingCampusLabel(String rawValue, List<String> campusOptions) {
    final normalizedRaw = _normalizeForSearch(rawValue)
        .replaceAll('campus', '')
        .replaceAll('kampus', '')
        .trim();

    if (normalizedRaw.isEmpty) return '';

    for (final option in campusOptions) {
      final normalizedOption = _normalizeForSearch(option)
          .replaceAll('campus', '')
          .replaceAll('kampus', '')
          .trim();

      if (normalizedOption.isEmpty) continue;

      if (normalizedRaw.contains(normalizedOption) ||
          normalizedOption.contains(normalizedRaw)) {
        return option;
      }
    }

    if (normalizedRaw.contains('atak')) {
      return campusOptions.firstWhere(
        (option) => _normalizeForSearch(option).contains('atak'),
        orElse: () => rawValue.trim(),
      );
    }

    if (normalizedRaw.contains('incir')) {
      return campusOptions.firstWhere(
        (option) => _normalizeForSearch(option).contains('incir'),
        orElse: () => rawValue.trim(),
      );
    }

    if (normalizedRaw.contains('bas') || normalizedRaw.contains('ekspres')) {
      return campusOptions.firstWhere(
        (option) {
          final normalizedOption = _normalizeForSearch(option);
          return normalizedOption.contains('bas') ||
              normalizedOption.contains('ekspres') ||
              normalizedOption.contains('kucuk');
        },
        orElse: () => rawValue.trim(),
      );
    }

    if (normalizedRaw.contains('sirin') || normalizedRaw.contains('bahcel')) {
      return campusOptions.firstWhere(
        (option) {
          final normalizedOption = _normalizeForSearch(option);
          return normalizedOption.contains('sirin') || normalizedOption.contains('bahcel');
        },
        orElse: () => rawValue.trim(),
      );
    }

    return rawValue.trim();
  }

  String _classroomCampusLabel(
    Map<dynamic, dynamic> classroom,
    List<String> campusOptions,
  ) {
    final rawCandidates = <String>[
      classroom['campus']?.toString() ?? '',
      (classroom['building']?.toString() ?? '').split(',').first.trim(),
      (classroom['location']?.toString() ?? '').split(',').first.trim(),
    ].where((value) => value.trim().isNotEmpty).toList();

    for (final candidate in rawCandidates) {
      final match = _bestMatchingCampusLabel(candidate, campusOptions);
      if (match.trim().isNotEmpty) return match;
    }

    return campusOptions.isNotEmpty ? campusOptions.first : "Unknown Campus";
  }

  bool _looksLikeFloorText(String value) {
    final normalized = _normalizeForSearch(value);
    return normalized.contains('floor') ||
        normalized.contains('kat') ||
        normalized == 'b1' ||
        normalized == 'b2' ||
        RegExp(r'^[0-9]+(st|nd|rd|th)?$').hasMatch(normalized);
  }

  String _classroomLocationLabel(
    Map<dynamic, dynamic> classroom,
    List<String> campusOptions,
  ) {
    final campus = _classroomCampusLabel(classroom, campusOptions);
    final rawLocation = classroom['location']?.toString().trim() ?? '';
    final rawBuilding = classroom['building']?.toString().trim() ?? '';
    final rawValues = <String>[rawLocation, rawBuilding]
        .where((value) => value.trim().isNotEmpty)
        .toList();

    for (final rawValue in rawValues) {
      final parts = rawValue
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();

      final buildingCandidates = parts.where((part) {
        final normalizedPart = _normalizeForSearch(part);
        final normalizedCampus = _normalizeForSearch(campus);
        final campusWithoutWord = normalizedCampus.replaceAll('campus', '').trim();

        return normalizedPart != normalizedCampus &&
            normalizedPart != campusWithoutWord &&
            !_looksLikeFloorText(part);
      }).toList();

      if (buildingCandidates.isNotEmpty) {
        return buildingCandidates.last;
      }

      if (parts.length == 1 && !_looksLikeFloorText(parts.first)) {
        return parts.first;
      }
    }

    return "General Building";
  }

  String _classroomFloorLabel(Map<dynamic, dynamic> classroom) {
    final floorLabel = classroom['floorLabel']?.toString().trim() ?? '';
    if (floorLabel.isNotEmpty) return _floorLabelFromValue(floorLabel);

    final floor = classroom['floor']?.toString().trim() ?? '';
    if (floor.isNotEmpty) return _floorLabelFromValue(floor);

    final location = classroom['location']?.toString() ?? '';
    final building = classroom['building']?.toString() ?? '';
    final combined = '$location, $building';

    final b2Match = RegExp(r'\bB2\b', caseSensitive: false).firstMatch(combined);
    if (b2Match != null) return "B2 Floor";

    final b1Match = RegExp(r'\bB1\b', caseSensitive: false).firstMatch(combined);
    if (b1Match != null) return "B1 Floor";

    return "Ground Floor";
  }

  int _floorSortValue(String label) {
    final normalized = _normalizeForSearch(label);
    if (normalized.contains('b2')) return -2;
    if (normalized.contains('b1') || normalized.contains('basement')) return -1;
    if (normalized.contains('ground')) return 0;

    final match = RegExp(r'(\d+)').firstMatch(label);
    return int.tryParse(match?.group(1) ?? '0') ?? 0;
  }

  int _activeClassroomFilterCount() {
    return [
      _classroomCampusFilter,
      _classroomLocationFilter,
      _classroomFloorFilter,
      _classroomTypeFilter,
    ].where((value) => value != _classroomFilterAll).length;
  }

  List<String> _classroomFilterOptions(Iterable<String> rawOptions) {
    final options = rawOptions
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return <String>[_classroomFilterAll, ...options];
  }

  List<String> _classroomFloorFilterOptions(Iterable<String> rawOptions) {
    final options = rawOptions
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => _floorSortValue(a).compareTo(_floorSortValue(b)));

    return <String>[_classroomFilterAll, ...options];
  }

  bool _matchesClassroomFilter(
    Map<String, dynamic> classroom,
    List<String> campusOptions, {
    required String searchQuery,
    required String campusFilter,
    required String locationFilter,
    required String floorFilter,
    required String typeFilter,
  }) {
    if (!_isClassroomEducationSpace(classroom)) return false;

    final campus = _classroomCampusLabel(classroom, campusOptions);
    final location = _classroomLocationLabel(classroom, campusOptions);
    final floor = _classroomFloorLabel(classroom);
    final type = _normalizeClassroomType(classroom['type']);

    if (campusFilter != _classroomFilterAll && campus != campusFilter) return false;
    if (locationFilter != _classroomFilterAll && location != locationFilter) return false;
    if (floorFilter != _classroomFilterAll && floor != floorFilter) return false;
    if (typeFilter != _classroomFilterAll && type != typeFilter) return false;

    if (searchQuery.isEmpty) return true;

    final searchableText = [
      classroom['name']?.toString() ?? '',
      classroom['building']?.toString() ?? '',
      classroom['location']?.toString() ?? '',
      campus,
      location,
      floor,
      type,
    ].map(_normalizeForSearch).join(' ');

    return searchableText.contains(searchQuery);
  }

  List<Map<String, dynamic>> _educationClassroomsFromRaw(
    List<dynamic> rawClassrooms,
  ) {
    return rawClassrooms
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => _isClassroomEducationSpace(item))
        .toList();
  }

  void _clearClassroomFilters() {
    setState(() {
      _classroomCampusFilter = _classroomFilterAll;
      _classroomLocationFilter = _classroomFilterAll;
      _classroomFloorFilter = _classroomFilterAll;
      _classroomTypeFilter = _classroomFilterAll;
    });
  }

  Widget _buildClassroomFilterButton(
    List<Map<String, dynamic>> classrooms,
    List<String> campusOptions,
  ) {
    final activeCount = _activeClassroomFilterCount();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _adminBorderColor()),
          ),
          child: IconButton(
            tooltip: "Filter classrooms",
            icon: Icon(
              Icons.tune,
              color: activeCount > 0 ? _adminPrimaryColor() : _adminTextMutedColor(),
            ),
            onPressed: () => _openClassroomFilterSheet(
              classrooms: classrooms,
              campusOptions: campusOptions,
            ),
          ),
        ),
        if (activeCount > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppTheme.destructiveColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                activeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveClassroomFilterChips() {
    final filters = <Map<String, VoidCallback>>[];

    if (_classroomCampusFilter != _classroomFilterAll) {
      filters.add({
        "Campus: $_classroomCampusFilter": () {
          setState(() {
            _classroomCampusFilter = _classroomFilterAll;
            _classroomLocationFilter = _classroomFilterAll;
            _classroomFloorFilter = _classroomFilterAll;
          });
        },
      });
    }

    if (_classroomLocationFilter != _classroomFilterAll) {
      filters.add({
        "Building: $_classroomLocationFilter": () {
          setState(() {
            _classroomLocationFilter = _classroomFilterAll;
            _classroomFloorFilter = _classroomFilterAll;
          });
        },
      });
    }

    if (_classroomFloorFilter != _classroomFilterAll) {
      filters.add({
        "Floor: $_classroomFloorFilter": () {
          setState(() {
            _classroomFloorFilter = _classroomFilterAll;
          });
        },
      });
    }

    if (_classroomTypeFilter != _classroomFilterAll) {
      filters.add({
        "Type: $_classroomTypeFilter": () {
          setState(() {
            _classroomTypeFilter = _classroomFilterAll;
          });
        },
      });
    }

    if (filters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final label = filter.keys.first;
            final onDeleted = filter.values.first;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(label),
                onDeleted: onDeleted,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: TextStyle(
                  color: _adminTextPrimaryColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                deleteIconColor: _adminTextMutedColor(),
                backgroundColor: _adminPrimaryColor().withOpacity(0.08),
                side: BorderSide(color: _adminPrimaryColor().withOpacity(0.25)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _openClassroomFilterSheet({
    required List<Map<String, dynamic>> classrooms,
    required List<String> campusOptions,
  }) {
    String tempCampus = _classroomCampusFilter;
    String tempLocation = _classroomLocationFilter;
    String tempFloor = _classroomFloorFilter;
    String tempType = _classroomTypeFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final campusFilterOptions = _classroomFilterOptions(
              classrooms.map((item) => _classroomCampusLabel(item, campusOptions)),
            );

            if (!campusFilterOptions.contains(tempCampus)) {
              tempCampus = _classroomFilterAll;
            }

            final locationSource = classrooms.where((item) {
              if (tempCampus == _classroomFilterAll) return true;
              return _classroomCampusLabel(item, campusOptions) == tempCampus;
            }).toList();

            final locationFilterOptions = _classroomFilterOptions(
              locationSource.map((item) => _classroomLocationLabel(item, campusOptions)),
            );

            if (!locationFilterOptions.contains(tempLocation)) {
              tempLocation = _classroomFilterAll;
            }

            final floorSource = locationSource.where((item) {
              if (tempLocation == _classroomFilterAll) return true;
              return _classroomLocationLabel(item, campusOptions) == tempLocation;
            }).toList();

            final floorFilterOptions = _classroomFloorFilterOptions(
              floorSource.map((item) => _classroomFloorLabel(item)),
            );

            if (!floorFilterOptions.contains(tempFloor)) {
              tempFloor = _classroomFilterAll;
            }

            final typeFilterOptions = <String>[
              _classroomFilterAll,
              "Classroom",
              "Laboratory",
              "Amphitheater",
            ];

            if (!typeFilterOptions.contains(tempType)) {
              tempType = _classroomFilterAll;
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _adminBorderColor(),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Filter Classrooms",
                              style: TextStyle(
                                color: _adminTextPrimaryColor(),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: "Close",
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildDropdown(
                        "Campus",
                        campusFilterOptions,
                        value: tempCampus,
                        onChanged: (value) {
                          setSheetState(() {
                            tempCampus = value ?? _classroomFilterAll;
                            tempLocation = _classroomFilterAll;
                            tempFloor = _classroomFilterAll;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        "Building / Location",
                        locationFilterOptions,
                        value: tempLocation,
                        onChanged: (value) {
                          setSheetState(() {
                            tempLocation = value ?? _classroomFilterAll;
                            tempFloor = _classroomFilterAll;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        "Floor",
                        floorFilterOptions,
                        value: tempFloor,
                        onChanged: (value) {
                          setSheetState(() {
                            tempFloor = value ?? _classroomFilterAll;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        "Classroom Type",
                        typeFilterOptions,
                        value: tempType,
                        onChanged: (value) {
                          setSheetState(() {
                            tempType = value ?? _classroomFilterAll;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  tempCampus = _classroomFilterAll;
                                  tempLocation = _classroomFilterAll;
                                  tempFloor = _classroomFilterAll;
                                  tempType = _classroomFilterAll;
                                });
                              },
                              child: const Text("Clear"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _classroomCampusFilter = tempCampus;
                                  _classroomLocationFilter = tempLocation;
                                  _classroomFloorFilter = tempFloor;
                                  _classroomTypeFilter = tempType;
                                });
                                Navigator.pop(sheetContext);
                              },
                              child: const Text("Apply Filters"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
          return _buildErrorState("Failed to fetch Campus Units data.", onRetry: () => _refreshTab(1));
        }

        final allUnits = snapshot.data ?? <Map<String, dynamic>>[];
        final sq = _normalizeForSearch(_searchControllers[1]!.text);

        final filteredUnits = allUnits.where((unit) {
          final normalizedUnit = DataService.normalizeCampusUnitRecord(unit);

          if (!DataService.isCampusUnitVisible(normalizedUnit)) {
            return false;
          }

          final name = normalizedUnit['name']?.toString() ?? '';
          final location = normalizedUnit['location']?.toString() ?? '';
          final type = normalizedUnit['type']?.toString() ?? '';
          final category = normalizedUnit['category']?.toString() ?? '';

          if (sq.isEmpty) return true;

          return _normalizeForSearch(name).contains(sq) ||
              _normalizeForSearch(location).contains(sq) ||
              _normalizeForSearch(type).contains(sq) ||
              _normalizeForSearch(category).contains(sq);
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
                  Text("Campus Units (${filteredUnits.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => _openBuildingForm(isEdit: false),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add"),
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
                  final unitsForCampus = filteredUnits.where((unit) => _unitCampusKey(unit) == campus['key']).toList()
                    ..sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

                  return _buildCampusUnitCard(title: campus['title']!, campusKey: campus['key']!, units: unitsForCampus);
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
        final educationClassrooms = _educationClassroomsFromRaw(allClassrooms);
        final sq = _normalizeForSearch(_searchControllers[2]!.text);

        final filteredClassrooms = educationClassrooms.where((classroom) {
          return _matchesClassroomFilter(
            classroom,
            campusOptions,
            searchQuery: sq,
            campusFilter: _classroomCampusFilter,
            locationFilter: _classroomLocationFilter,
            floorFilter: _classroomFloorFilter,
            typeFilter: _classroomTypeFilter,
          );
        }).toList()
          ..sort((a, b) {
            final campusCompare = _classroomCampusLabel(a, campusOptions)
                .compareTo(_classroomCampusLabel(b, campusOptions));
            if (campusCompare != 0) return campusCompare;

            final locationCompare = _classroomLocationLabel(a, campusOptions)
                .compareTo(_classroomLocationLabel(b, campusOptions));
            if (locationCompare != 0) return locationCompare;

            final floorCompare = _floorSortValue(_classroomFloorLabel(a))
                .compareTo(_floorSortValue(_classroomFloorLabel(b)));
            if (floorCompare != 0) return floorCompare;

            return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
          });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Classrooms (${filteredClassrooms.length})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openClassroomForm(
                      isEdit: false,
                      campusOptions: campusOptions,
                      locationsByCampus: classroomLocationsByCampus,
                    ),
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
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchControllers[2]!,
                      placeholder: "Search classroom...",
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildClassroomFilterButton(educationClassrooms, campusOptions),
                ],
              ),
            ),
            _buildActiveClassroomFilterChips(),
            const SizedBox(height: 12),
            Expanded(
              child: filteredClassrooms.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 42,
                              color: _adminTextMutedColor(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No classrooms match the current search/filter.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _adminTextPrimaryColor(),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_activeClassroomFilterCount() > 0) ...[
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: _clearClassroomFilters,
                                icon: const Icon(Icons.clear),
                                label: const Text("Clear filters"),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filteredClassrooms.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final classroom = filteredClassrooms[index];
                        final campus = _classroomCampusLabel(classroom, campusOptions);
                        final location = _classroomLocationLabel(classroom, campusOptions);
                        final floor = _classroomFloorLabel(classroom);
                        final type = _normalizeClassroomType(classroom['type']);

                        return _buildListItem(
                          classroom['name']?.toString() ?? '',
                          "$campus • $location • $floor • $type",
                          () => _openClassroomForm(
                            isEdit: true,
                            item: classroom,
                            campusOptions: campusOptions,
                            locationsByCampus: classroomLocationsByCampus,
                          ),
                          () => _showDeleteDialog(
                            'classrooms',
                            (classroom['firestoreDocId'] ?? classroom['id']).toString(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  int _activeInstructorFilterCount() {
    int count = 0;
    if (_instructorDepartmentFilter != _instructorFilterAll) count++;
    if (_instructorDayFilter != _instructorFilterAll) count++;
    return count;
  }

  String _instructorDepartmentLabel(dynamic value) {
    final department = value?.toString().trim();
    if (department == null || department.isEmpty) return 'Unknown Department';
    return department;
  }

  String _instructorDayLabel(dynamic value) {
    final day = value?.toString().trim();
    if (day == null || day.isEmpty) return 'Unknown Day';
    return day;
  }

  List<Map<String, dynamic>> _instructorOfficeHours(Map<String, dynamic> instructor) {
    final rawOfficeHours = instructor['officeHours'];
    if (rawOfficeHours is! List) return [];

    return rawOfficeHours
        .whereType<Map>()
        .map((slot) => Map<String, dynamic>.from(slot))
        .toList();
  }

  List<String> _instructorDepartmentOptions(List<Map<String, dynamic>> instructors) {
    final departments = <String>{};

    for (final instructor in instructors) {
      final department = _instructorDepartmentLabel(instructor['department']);
      if (department.isNotEmpty) departments.add(department);
    }

    final sortedDepartments = departments.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [_instructorFilterAll, ...sortedDepartments];
  }

  List<String> _instructorDayOptions(List<Map<String, dynamic>> instructors) {
    final days = <String>{
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    };

    for (final instructor in instructors) {
      for (final slot in _instructorOfficeHours(instructor)) {
        final day = _instructorDayLabel(slot['day']);
        if (day.isNotEmpty && day != 'Unknown Day') days.add(day);
      }
    }

    final sortedDays = days.toList()
      ..sort((a, b) {
        const order = {
          'Monday': 1,
          'Tuesday': 2,
          'Wednesday': 3,
          'Thursday': 4,
          'Friday': 5,
          'Saturday': 6,
          'Sunday': 7,
        };

        final aOrder = order[a] ?? 99;
        final bOrder = order[b] ?? 99;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    return [_instructorFilterAll, ...sortedDays];
  }

  bool _matchesInstructorFilters(Map<String, dynamic> instructor) {
    if (_instructorDepartmentFilter != _instructorFilterAll &&
        _normalizeForSearch(_instructorDepartmentLabel(instructor['department'])) !=
            _normalizeForSearch(_instructorDepartmentFilter)) {
      return false;
    }

    if (_instructorDayFilter != _instructorFilterAll) {
      final hasMatchingDay = _instructorOfficeHours(instructor).any((slot) {
        return _normalizeForSearch(_instructorDayLabel(slot['day'])) ==
            _normalizeForSearch(_instructorDayFilter);
      });

      if (!hasMatchingDay) return false;
    }

    return true;
  }

  bool _matchesInstructorSearch(Map<String, dynamic> instructor, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;

    final officeHoursText = _instructorOfficeHours(instructor).map((slot) {
      final day = slot['day']?.toString() ?? '';
      final start = slot['startTime']?.toString() ?? '';
      final end = slot['endTime']?.toString() ?? '';
      final office = slot['office']?.toString() ?? '';
      return '$day $start $end $office';
    }).join(' ');

    final searchableText = [
      instructor['name'],
      instructor['department'],
      instructor['title'],
      instructor['office'],
      instructor['email'],
      officeHoursText,
    ].map((value) => value?.toString() ?? '').join(' ');

    return _normalizeForSearch(searchableText).contains(normalizedQuery);
  }

  Widget _buildInstructorFilterButton(List<Map<String, dynamic>> instructors) {
    final activeCount = _activeInstructorFilterCount();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _adminBorderColor()),
          ),
          child: IconButton(
            tooltip: "Filter instructors",
            icon: Icon(
              Icons.tune,
              color: activeCount > 0 ? _adminPrimaryColor() : _adminTextMutedColor(),
            ),
            onPressed: () => _openInstructorFilterSheet(instructors),
          ),
        ),
        if (activeCount > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppTheme.destructiveColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                activeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openInstructorFilterSheet(List<Map<String, dynamic>> instructors) {
    String tempDepartment = _instructorDepartmentFilter;
    String tempDay = _instructorDayFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final media = MediaQuery.of(sheetContext);
            final departmentOptions = _instructorDepartmentOptions(instructors);
            final dayOptions = _instructorDayOptions(instructors);
            final maxChipLabelWidth = media.size.width - 88;

            if (!departmentOptions.contains(tempDepartment)) {
              tempDepartment = _instructorFilterAll;
            }

            if (!dayOptions.contains(tempDay)) {
              tempDay = _instructorFilterAll;
            }

            Widget buildFilterChip({
              required String label,
              required bool selected,
              required VoidCallback onSelected,
            }) {
              return ChoiceChip(
                label: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxChipLabelWidth),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                selected: selected,
                onSelected: (_) => onSelected(),
                selectedColor: _adminPrimaryColor().withValues(alpha: 0.14),
                backgroundColor: Theme.of(sheetContext).cardColor,
                side: BorderSide(
                  color: selected ? _adminPrimaryColor() : _adminBorderColor(),
                ),
                labelStyle: TextStyle(
                  color: selected ? _adminPrimaryColor() : _adminTextMutedColor(),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }

            return SafeArea(
              top: false,
              child: SizedBox(
                height: media.size.height * 0.82,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Filter Instructors",
                              style: TextStyle(
                                color: _adminTextPrimaryColor(),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: "Close",
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Department",
                              style: TextStyle(
                                color: _adminTextPrimaryColor(),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: departmentOptions.map((department) {
                                return buildFilterChip(
                                  label: department,
                                  selected: tempDepartment == department,
                                  onSelected: () {
                                    setSheetState(() {
                                      tempDepartment = department;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              "Office Day",
                              style: TextStyle(
                                color: _adminTextPrimaryColor(),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: dayOptions.map((day) {
                                return buildFilterChip(
                                  label: day,
                                  selected: tempDay == day,
                                  onSelected: () {
                                    setSheetState(() {
                                      tempDay = day;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        16 + media.viewInsets.bottom,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(sheetContext).scaffoldBackgroundColor,
                        border: Border(
                          top: BorderSide(color: _adminBorderColor()),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  tempDepartment = _instructorFilterAll;
                                  tempDay = _instructorFilterAll;
                                });
                              },
                              child: const Text("Clear"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _instructorDepartmentFilter = tempDepartment;
                                  _instructorDayFilter = tempDay;
                                });
                                Navigator.pop(sheetContext);
                              },
                              child: const Text("Apply"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInstructorsTab() {
    final future = _instructorsFuture;

    if (future == null) {
      Future.microtask(() => _ensureTabFuture(3));
      return _buildListSkeleton("Loading Instructors...");
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListSkeleton("Loading Instructors...");
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            "Failed to fetch Instructors data.",
            onRetry: () => _refreshTab(3),
          );
        }

        final allInstructors = snapshot.data ?? [];
        final searchController = _searchControllers[3]!;
        final normalizedQuery = _normalizeForSearch(searchController.text);

        final filteredInstructors = allInstructors.where((instructor) {
          return _matchesInstructorSearch(instructor, normalizedQuery) &&
              _matchesInstructorFilters(instructor);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Instructors (${filteredInstructors.length})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openInstructorForm(isEdit: false),
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
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: searchController,
                      placeholder: "Search instructors...",
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildInstructorFilterButton(allInstructors),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredInstructors.isEmpty
                  ? Center(
                child: Text(
                  "No instructors match the current search/filter.",
                  style: TextStyle(color: _adminTextMutedColor()),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                itemCount: filteredInstructors.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final instructor = filteredInstructors[index];
                  final name = instructor['name']?.toString().trim();
                  final department = _instructorDepartmentLabel(instructor['department']);
                  final title = instructor['title']?.toString().trim() ?? '';
                  final office = instructor['office']?.toString().trim() ?? '';

                  final subtitleParts = <String>[
                    department,
                    if (title.isNotEmpty) title,
                    if (office.isNotEmpty) office,
                  ];

                  return _buildListItem(
                    name == null || name.isEmpty ? 'Unnamed instructor' : name,
                    subtitleParts.join(' • '),
                        () => _openInstructorForm(isEdit: true, item: instructor),
                        () => _showDeleteDialog(
                      'instructors',
                      (instructor['firestoreDocId'] ?? instructor['id']).toString(),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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

  int _activeAnnouncementFilterCount() {
    return _announcementCategoryFilter == _announcementFilterAll ? 0 : 1;
  }

  String _announcementCategoryLabel(dynamic value) {
    final category = value?.toString().trim();
    if (category == null || category.isEmpty) return 'general';
    return category;
  }

  List<String> _announcementCategoryOptions(List<Map<String, dynamic>> announcements) {
    final categories = <String>{
      _announcementFilterAll,
      'general',
      'academic',
      'admin',
      'scholarship',
    };

    for (final announcement in announcements) {
      final category = _announcementCategoryLabel(announcement['category']);
      if (category.isNotEmpty) categories.add(category);
    }

    return categories.toList();
  }

  bool _matchesAnnouncementFilters(Map<String, dynamic> announcement) {
    if (_announcementCategoryFilter != _announcementFilterAll &&
        _announcementCategoryLabel(announcement['category']) != _announcementCategoryFilter) {
      return false;
    }

    return true;
  }

  Widget _buildAnnouncementFilterButton(List<Map<String, dynamic>> announcements) {
    final activeCount = _activeAnnouncementFilterCount();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _adminBorderColor()),
          ),
          child: IconButton(
            tooltip: "Filter announcements",
            icon: Icon(
              Icons.tune,
              color: activeCount > 0 ? _adminPrimaryColor() : _adminTextMutedColor(),
            ),
            onPressed: () => _openAnnouncementFilterSheet(announcements),
          ),
        ),
        if (activeCount > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppTheme.destructiveColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                activeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openAnnouncementFilterSheet(List<Map<String, dynamic>> announcements) {
    String tempCategory = _announcementCategoryFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final categoryOptions = _announcementCategoryOptions(announcements);

            if (!categoryOptions.contains(tempCategory)) {
              tempCategory = _announcementFilterAll;
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Filter Announcements",
                            style: TextStyle(
                              color: _adminTextPrimaryColor(),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: "Close",
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Category",
                      style: TextStyle(
                        color: _adminTextPrimaryColor(),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categoryOptions.map((category) {
                        final selected = tempCategory == category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) {
                            setSheetState(() {
                              tempCategory = category;
                            });
                          },
                          selectedColor: _adminPrimaryColor().withValues(alpha: 0.14),
                          backgroundColor: Theme.of(context).cardColor,
                          side: BorderSide(
                            color: selected ? _adminPrimaryColor() : _adminBorderColor(),
                          ),
                          labelStyle: TextStyle(
                            color: selected ? _adminPrimaryColor() : _adminTextMutedColor(),
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                tempCategory = _announcementFilterAll;
                              });
                            },
                            child: const Text("Clear"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _announcementCategoryFilter = tempCategory;
                              });
                              Navigator.pop(sheetContext);
                            },
                            child: const Text("Apply"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementsTab() {
    final future = _announcementsFuture;

    if (future == null) {
      Future.microtask(() => _ensureTabFuture(5));
      return _buildListSkeleton("Loading Announcements...");
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListSkeleton("Loading Announcements...");
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            "Failed to fetch Announcements data.",
            onRetry: () => _refreshTab(5),
          );
        }

        final allAnnouncements = snapshot.data ?? [];
        final searchQuery = _normalizeForSearch(_searchControllers[5]!.text);

        final filteredAnnouncements = allAnnouncements.where((announcement) {
          if (!_matchesAnnouncementFilters(announcement)) return false;

          if (searchQuery.isEmpty) return true;

          final searchableText = [
            announcement['title']?.toString() ?? '',
            announcement['content']?.toString() ?? '',
            announcement['date']?.toString() ?? '',
            announcement['publishDate']?.toString() ?? '',
            announcement['category']?.toString() ?? '',
          ].map(_normalizeForSearch).join(' ');

          return searchableText.contains(searchQuery);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Announcements (${filteredAnnouncements.length})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openAnnouncementForm(isEdit: false),
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
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchControllers[5]!,
                      placeholder: "Search announcements...",
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildAnnouncementFilterButton(allAnnouncements),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredAnnouncements.isEmpty
                  ? Center(
                      child: Text(
                        "No announcements match the current search/filter.",
                        style: TextStyle(color: _adminTextMutedColor()),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      itemCount: filteredAnnouncements.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final announcement = filteredAnnouncements[index];
                        return _buildListItem(
                          announcement['title'] ?? '',
                          announcement['date'] ?? '',
                          () => _openAnnouncementForm(isEdit: true, item: announcement),
                          () => _showDeleteDialog(
                            'announcements',
                            (announcement['firestoreDocId'] ?? announcement['id']).toString(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
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
        return _buildIssuesTab(allIssues, _searchControllers[8]!);
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
                    "If you disable the day tick, students will see no food for that day. Meal is saved daily. Breakfast and Fast Food are fixed global menus, so one update is shown on every day.",
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
            DataService.isFixedCafeteriaMealType(mealType)
                ? (nextValue
                    ? "$mealType global menu made visible to students."
                    : "$mealType global menu hidden from students.")
                : (nextValue
                    ? "$mealType made visible to students."
                    : "$mealType hidden from students."),
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
                              final isFixedMenu = menu['isFixedMenu'] == true;
                              final scopeLabel = isFixedMenu ? "Global fixed" : "Daily";

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
                                    "$scopeLabel • $mealType • ${menu['time'] ?? '-'} • ${menu['price'] ?? '-'} • ${items.length} items",
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
          final isFixedMenu = DataService.isFixedCafeteriaMealType(normalizedMealType);

          return AlertDialog(
            title: Text(
              isFixedMenu
                  ? "$normalizedMealType - Global Fixed Menu"
                  : "${DataService.weekdayName(date.weekday)} - $normalizedMealType",
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
                      hintText: isFastFood ? "Product based" : "e.g. ₺175",
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
                    "contentManuallyEdited": !DataService.isFixedCafeteriaMealType(normalizedMealType),
                    "templateAlgorithmVersion": item['templateAlgorithmVersion'] ?? 3,
                    "templateId": item['templateId'],
                    "templateRotationIndex": item['templateRotationIndex'],
                  };

                  await DataService.saveCafeteriaMenu(
                    date: date,
                    mealType: normalizedMealType,
                    menu: menuData,
                  );

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          DataService.isFixedCafeteriaMealType(normalizedMealType)
                              ? "$normalizedMealType global menu updated in Firebase database."
                              : "Daily menu updated in Firebase database.",
                        ),
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

  int _activeIssueFilterCount() {
    var count = 0;
    if (_issueStatusFilter != 'all') count++;
    if (_issuePriorityFilter != 'all') count++;
    return count;
  }

  String _normalizeIssueStatus(dynamic rawStatus) {
    final value = rawStatus?.toString().trim().toLowerCase() ?? 'open';
    if (value == 'resolved' || value == 'closed' || value == 'çözüldü') {
      return 'resolved';
    }
    return 'open';
  }

  String _normalizeIssuePriority(dynamic rawPriority) {
    final value = rawPriority?.toString().trim().toLowerCase() ?? 'normal';

    if (value == 'high' || value == 'yüksek') return 'high';
    if (value == 'medium' || value == 'orta') return 'medium';
    if (value == 'low' || value == 'düşük') return 'normal';
    if (value == 'normal') return 'normal';

    return 'normal';
  }

  String _issueStatusLabel(String status) {
    return status == 'resolved' ? 'Resolved' : 'Open';
  }

  String _issuePriorityLabel(String priority) {
    if (priority == 'high') return 'High';
    if (priority == 'medium') return 'Medium';
    return 'Normal';
  }

  Color _issuePriorityColor(String priority) {
    if (priority == 'high') return AppTheme.destructiveColor;
    if (priority == 'medium') return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  String _issueTitle(Map<dynamic, dynamic> issue) {
    return issue['title']?.toString().trim().isNotEmpty == true
        ? issue['title'].toString()
        : (issue['subject']?.toString().trim().isNotEmpty == true
        ? issue['subject'].toString()
        : 'Untitled issue');
  }

  String _issueCreatedText(Map<dynamic, dynamic> issue) {
    final dateText = issue['date']?.toString();
    if (dateText != null && dateText.trim().isNotEmpty) {
      return dateText;
    }

    final createdAt = issue['createdAt'];
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year} "
          "${date.hour.toString().padLeft(2, '0')}:"
          "${date.minute.toString().padLeft(2, '0')}";
    }

    return '-';
  }

  Widget _buildIssueFilterButton() {
    final activeCount = _activeIssueFilterCount();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _adminBorderColor()),
          ),
          child: IconButton(
            tooltip: "Filter issues",
            icon: Icon(
              Icons.tune,
              color: activeCount > 0 ? _adminPrimaryColor() : _adminTextMutedColor(),
            ),
            onPressed: _openIssueFilterSheet,
          ),
        ),
        if (activeCount > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppTheme.destructiveColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                activeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _issueFilterChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? _adminPrimaryColor();

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.14),
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(
        color: selected ? color : _adminBorderColor(),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? color : _adminTextMutedColor(),
      ),
    );
  }

  void _openIssueFilterSheet() {
    String tempStatus = _issueStatusFilter;
    String tempPriority = _issuePriorityFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Filter Issues",
                            style: TextStyle(
                              color: _adminTextPrimaryColor(),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: "Close",
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Status",
                      style: TextStyle(
                        color: _adminTextPrimaryColor(),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _issueFilterChoiceChip(
                          label: "All",
                          selected: tempStatus == 'all',
                          onTap: () => setSheetState(() => tempStatus = 'all'),
                        ),
                        _issueFilterChoiceChip(
                          label: "Open",
                          selected: tempStatus == 'open',
                          activeColor: AppTheme.warningColor,
                          onTap: () => setSheetState(() => tempStatus = 'open'),
                        ),
                        _issueFilterChoiceChip(
                          label: "Resolved",
                          selected: tempStatus == 'resolved',
                          activeColor: AppTheme.successColor,
                          onTap: () => setSheetState(() => tempStatus = 'resolved'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Priority",
                      style: TextStyle(
                        color: _adminTextPrimaryColor(),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _issueFilterChoiceChip(
                          label: "All Priority",
                          selected: tempPriority == 'all',
                          onTap: () => setSheetState(() => tempPriority = 'all'),
                        ),
                        _issueFilterChoiceChip(
                          label: "Normal",
                          selected: tempPriority == 'normal',
                          activeColor: AppTheme.successColor,
                          onTap: () => setSheetState(() => tempPriority = 'normal'),
                        ),
                        _issueFilterChoiceChip(
                          label: "Medium",
                          selected: tempPriority == 'medium',
                          activeColor: AppTheme.warningColor,
                          onTap: () => setSheetState(() => tempPriority = 'medium'),
                        ),
                        _issueFilterChoiceChip(
                          label: "High",
                          selected: tempPriority == 'high',
                          activeColor: AppTheme.destructiveColor,
                          onTap: () => setSheetState(() => tempPriority = 'high'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                tempStatus = 'all';
                                tempPriority = 'all';
                              });
                            },
                            child: const Text("Clear"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _issueStatusFilter = tempStatus;
                                _issuePriorityFilter = tempPriority;
                              });
                              Navigator.pop(sheetContext);
                            },
                            child: const Text("Apply"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIssuesTab(List<dynamic> issues, TextEditingController searchController) {
    final sq = _normalizeForSearch(searchController.text);

    final filteredIssues = issues.where((issue) {
      final issueMap = issue as Map<dynamic, dynamic>;
      final status = _normalizeIssueStatus(issueMap["status"]);
      final priority = _normalizeIssuePriority(issueMap["priority"]);

      final matchesStatus = _issueStatusFilter == 'all' ||
          _issueStatusFilter == status;

      final matchesPriority = _issuePriorityFilter == 'all' ||
          _issuePriorityFilter == priority;

      if (!matchesStatus || !matchesPriority) return false;

      if (sq.isEmpty) return true;

      final searchableText = [
        _issueTitle(issueMap),
        issueMap['category']?.toString() ?? '',
        issueMap['location']?.toString() ?? '',
        issueMap['studentName']?.toString() ?? '',
        issueMap['studentEmail']?.toString() ?? '',
        _issueStatusLabel(status),
        _issuePriorityLabel(priority),
        issueMap['description']?.toString() ?? '',
      ].map(_normalizeForSearch).join(' ');

      return searchableText.contains(sq);
    }).toList();

    final openIssues = filteredIssues.where((issue) {
      return _normalizeIssueStatus((issue as Map<dynamic, dynamic>)["status"]) != "resolved";
    }).toList();

    final resolvedIssues = filteredIssues.where((issue) {
      return _normalizeIssueStatus((issue as Map<dynamic, dynamic>)["status"]) == "resolved";
    }).toList();

    final sortedIssues = [...openIssues, ...resolvedIssues];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Incoming Issues (${sortedIssues.length})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: "Refresh issues",
                onPressed: () => _refreshTab(8),
                icon: Icon(
                  Icons.refresh,
                  color: _adminPrimaryColor(),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  controller: searchController,
                  placeholder: "Search issues...",
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              _buildIssueFilterButton(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: sortedIssues.isEmpty
              ? Center(
            child: Text(
              "No issue reports match the current search/filter.",
              style: TextStyle(color: _adminTextMutedColor()),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: sortedIssues.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final issue = sortedIssues[index] as Map<dynamic, dynamic>;

              final status = _normalizeIssueStatus(issue["status"]);
              final isResolved = status == "resolved";

              final priority = _normalizeIssuePriority(issue["priority"]);
              final priorityColor = _issuePriorityColor(priority);

              final title = _issueTitle(issue);
              final category = issue["category"]?.toString() ?? "-";
              final location = issue["location"]?.toString() ?? "Not specified";
              final studentName = issue["studentName"]?.toString() ?? "Unknown Student";
              final createdText = _issueCreatedText(issue);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _issuePriorityLabel(priority),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isResolved
                            ? AppTheme.successColor.withValues(alpha: 0.1)
                            : AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _issueStatusLabel(status),
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
                        title,
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
                    "$category • $location\n$studentName • $createdText",
                    style: TextStyle(color: _adminTextMutedColor()),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: _adminPrimaryColor(),
                      ),
                      onPressed: () => _openIssueDetailsDialog(issue),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: AppTheme.destructiveColor,
                      ),
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
    String issueTitle() {
      return issue['title']?.toString().trim().isNotEmpty == true
          ? issue['title'].toString()
          : (issue['subject']?.toString().trim().isNotEmpty == true
          ? issue['subject'].toString()
          : 'Untitled issue');
    }

    String normalizeStatus(dynamic rawStatus) {
      final value = rawStatus?.toString().trim().toLowerCase() ?? 'open';
      if (value == 'resolved' || value == 'closed' || value == 'çözüldü') {
        return 'resolved';
      }
      return 'open';
    }

    final status = normalizeStatus(issue['status']);
    final isResolved = status == 'resolved';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Issue Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Title: ${issueTitle()}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Category: ${issue["category"] ?? "-"}",
                style: TextStyle(color: _adminTextMutedColor()),
              ),
              const SizedBox(height: 4),
              Text(
                "Priority: ${issue["priority"] ?? "normal"}",
                style: TextStyle(color: _adminTextMutedColor()),
              ),
              const SizedBox(height: 4),
              Text(
                "Status: ${isResolved ? "Resolved" : "Open"}",
                style: TextStyle(color: _adminTextMutedColor()),
              ),
              const SizedBox(height: 4),
              Text(
                "Location: ${issue["location"] ?? "Not specified"}",
                style: TextStyle(color: _adminTextMutedColor()),
              ),
              const SizedBox(height: 12),
              Text(
                "Student: ${issue["studentName"] ?? "Unknown Student"}",
                style: TextStyle(color: _adminTextMutedColor()),
              ),
              const SizedBox(height: 4),
              Text(
                "Email: ${issue["studentEmail"] ?? "-"}",
                style: TextStyle(color: _adminTextMutedColor()),
              ),
              const Divider(height: 24),
              Text(
                issue["description"] ?? '',
                style: const TextStyle(height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          if (!isResolved)
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('issues')
                    .doc((issue['firestoreDocId'] ?? issue['id']).toString())
                    .update({
                  "status": "resolved",
                  "resolvedAt": FieldValue.serverTimestamp(),
                  "updatedAt": FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Issue marked as resolved.")),
                  );
                  _refreshAdminData(collectionKey: 'issues');
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text("Mark Resolved"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
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

    final List<String> gradeOptions = [
      "Prep",
      "1st Grade",
      "2nd Grade",
      "3rd Grade",
      "4th Grade",
      "Graduated",
    ];

    String? selectedGrade = item?['grade'];
    String? selectedAvatarId = item?['profileAvatarId']?.toString();

    if (selectedAvatarId != null &&
        !ProfileProvider.avatarOptions.any(
              (avatar) => avatar.id == selectedAvatarId,
        )) {
      selectedAvatarId = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEdit ? "Edit — Student" : "Add New Student",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField("Full Name", controller: nameCtrl),
                  const SizedBox(height: 12),
                  _buildTextField(
                    "Student ID",
                    isNumber: true,
                    controller: noCtrl,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField("Email", controller: emailCtrl),
                  const SizedBox(height: 12),
                  _buildTextField("Password", controller: passCtrl),
                  const SizedBox(height: 12),

                  _buildDropdown(
                    "Grade",
                    gradeOptions,
                    value: gradeOptions.contains(selectedGrade)
                        ? selectedGrade
                        : null,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedGrade = val;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: selectedAvatarId ?? 'none',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Profile Avatar",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'none',
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor:
                              Theme.of(context).dividerColor.withOpacity(0.4),
                              child: Icon(
                                Icons.person_outline,
                                size: 18,
                                color: _adminTextMutedColor(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text("No Avatar / Default"),
                          ],
                        ),
                      ),
                      ...ProfileProvider.avatarOptions.map((avatar) {
                        return DropdownMenuItem<String>(
                          value: avatar.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: avatar.color.withOpacity(0.14),
                                child: Icon(
                                  avatar.icon,
                                  size: 18,
                                  color: avatar.color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(avatar.label),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedAvatarId = value == 'none' ? null : value;
                      });
                    },
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
                  final String docId = isEdit
                      ? (item!['firestoreDocId'] ?? item['id']).toString()
                      : DateTime.now().millisecondsSinceEpoch.toString();

                  final Map<String, dynamic> newData = {
                    'id': int.tryParse(docId) ?? docId,
                    'name': nameCtrl.text.trim(),
                    'no': noCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'password': passCtrl.text.trim(),
                    'grade': selectedGrade ?? '1st Grade',
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (selectedAvatarId != null && selectedAvatarId!.isNotEmpty) {
                    newData['profileAvatarId'] = selectedAvatarId;
                    newData['profileAvatarUpdatedAt'] =
                        FieldValue.serverTimestamp();
                  } else if (isEdit) {
                    newData['profileAvatarId'] = FieldValue.delete();
                    newData['profileAvatarUpdatedAt'] =
                        FieldValue.serverTimestamp();
                  }

                  if (!isEdit) {
                    newData['createdAt'] = FieldValue.serverTimestamp();
                  }

                  await FirebaseFirestore.instance
                      .collection('students')
                      .doc(docId)
                      .set(newData, SetOptions(merge: true));

                  DataService.clearCollectionCache('students');

                  if (context.mounted) {
                    Navigator.pop(context);
                    _refreshAdminData(collectionKey: 'students');
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
      "Faculty",
      "Department",
      "Office",
      "Library",
      "Study Area",
      "Hall",
      "Auditorium",
      "Seminar Hall",
      "Conference Hall",
      "Food & Drink",
      "Cafeteria",
      "Cafe",
      "Restaurant",
      "Canteen",
      "Health Unit",
      "Infirmary",
      "Student Services",
      "Student Affairs",
      "Security",
      "Service",
      "Stationery",
      "Other",
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
      if (value.contains('classroom') ||
          value.contains('lecture hall') ||
          value.contains('lecture room') ||
          value.contains('laboratory') ||
          value == 'lab' ||
          value.contains(' lab') ||
          value.contains('amphitheater') ||
          value.contains('amfi') ||
          value.contains('workshop') ||
          value.contains('derslik') ||
          value.contains('sinif') ||
          value.contains('sınıf')) {
        return "Academic Unit";
      }

      if (value.contains('auditorium')) return "Auditorium";
      if (value.contains('seminar')) return "Seminar Hall";
      if (value.contains('conference')) return "Conference Hall";
      if (value.contains('hall') || value.contains('courtroom')) return "Hall";

      if (value.contains('library')) return "Library";
      if (value.contains('study')) return "Study Area";
      if (value.contains('health') ||
          value.contains('infirmary') ||
          value.contains('revir')) {
        return "Health Unit";
      }
      if (value.contains('cafeteria')) return "Cafeteria";
      if (value.contains('cafe')) return "Cafe";
      if (value.contains('restaurant')) return "Restaurant";
      if (value.contains('canteen')) return "Canteen";
      if (value.contains('food')) return "Food & Drink";
      if (value.contains('student affairs') || value.contains('registrar')) {
        return "Student Affairs";
      }
      if (value.contains('student service') || value.contains('student_services')) {
        return "Student Services";
      }
      if (value.contains('security')) return "Security";
      if (value.contains('office')) return "Office";
      if (value.contains('stationery') || value.contains('copy')) {
        return "Stationery";
      }
      if (value.contains('service') ||
          value.contains('bank') ||
          value.contains('hairdresser')) {
        return "Service";
      }

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
      "B2 Floor",
      "B1 Floor",
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
    final titleCtrl = TextEditingController(text: item?['title'] ?? 'Faculty Member');
    final officeLocCtrl = TextEditingController(text: item?['office'] ?? '');

    String initialEmail = item?['email']?.toString() ?? 'contact@uni.edu.tr';
    if (initialEmail.trim().isEmpty) initialEmail = 'contact@uni.edu.tr';
    final emailCtrl = TextEditingController(text: initialEmail);


    List<Map<String, dynamic>> _generateFallbackForAdmin(String id, String office) {
      final int seed = id.hashCode;
      final List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
      final List<String> blocks = ["09:00-11:00", "10:00-12:00", "11:00-13:00", "13:00-15:00", "14:00-16:00", "15:00-17:00"];

      String d1 = days[seed % 5];
      String b1 = blocks[seed % 6];
      String d2 = days[(seed + 2) % 5];
      String b2 = blocks[(seed + 3) % 6];

      return [
        {"day": d1, "startTime": b1.split('-')[0], "endTime": b1.split('-')[1], "office": office},
        {"day": d2, "startTime": b2.split('-')[0], "endTime": b2.split('-')[1], "office": office},
      ];
    }

    List<Map<String, dynamic>> officeHoursList = [];

    if (item != null) {
      if (item['officeHours'] != null && item['officeHours'] is List && (item['officeHours'] as List).isNotEmpty) {
        officeHoursList = List<Map<String, dynamic>>.from(
          (item['officeHours'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      } else {
        String instId = (item['firestoreDocId'] ?? item['id']).toString();
        officeHoursList = _generateFallbackForAdmin(instId, officeLocCtrl.text.isNotEmpty ? officeLocCtrl.text : "Office");
      }
    }

    final List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

    Future<String?> _selectTime(BuildContext context, String? currentTime) async {
      TimeOfDay initial = TimeOfDay.now();
      if (currentTime != null && currentTime.contains(':')) {
        final parts = currentTime.split(':');
        initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initial,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor)),
          child: child!,
        ),
      );
      if (picked != null) {
        return "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      }
      return null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? "Edit: Instructor" : "New Instructor", style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField("Full Name", controller: nameCtrl),
                    const SizedBox(height: 12),
                    _buildTextField("Department", controller: deptCtrl),
                    const SizedBox(height: 12),
                    _buildTextField("General Office", controller: officeLocCtrl),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Office Hours", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              officeHoursList.add({
                                "day": "Monday",
                                "startTime": "10:00",
                                "endTime": "12:00",
                                "office": officeLocCtrl.text.isNotEmpty ? officeLocCtrl.text : "Office"
                              });
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text("Add Slot"),
                        ),
                      ],
                    ),
                    const Divider(),

                    ...officeHoursList.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> oh = entry.value;

                      return Card(
                        margin: const EdgeInsets.all(4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown("Day", days, value: oh['day'], onChanged: (val) {
                                      setDialogState(() => oh['day'] = val);
                                    }),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => setDialogState(() => officeHoursList.removeAt(index)),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final t = await _selectTime(context, oh['startTime']);
                                        if (t != null) setDialogState(() => oh['startTime'] = t);
                                      },
                                      child: InputDecorator(
                                        decoration: const InputDecoration(labelText: "Start"),
                                        child: Text(oh['startTime'] ?? "09:00"),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final t = await _selectTime(context, oh['endTime']);
                                        if (t != null) setDialogState(() => oh['endTime'] = t);
                                      },
                                      child: InputDecorator(
                                        decoration: const InputDecoration(labelText: "End"),
                                        child: Text(oh['endTime'] ?? "11:00"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TextField(
                                decoration: const InputDecoration(labelText: "Room"),
                                onChanged: (val) => oh['office'] = val,
                                controller: TextEditingController(text: oh['office'])..selection = TextSelection.collapsed(offset: (oh['office'] ?? "").length),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 12),
                    _buildTextField("Email", controller: emailCtrl),
                    const SizedBox(height: 12),
                    _buildTextField("Photo Path", controller: photoCtrl),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  String docId = isEdit
                      ? (item!['firestoreDocId'] ?? item['id']).toString()
                      : DateTime.now().millisecondsSinceEpoch.toString();

                  Map<String, dynamic> newData = {
                    'id': docId,
                    'name': nameCtrl.text.trim(),
                    'department': deptCtrl.text.trim(),
                    'imageUrl': photoCtrl.text.trim(),
                    'officeHours': officeHoursList,
                    'title': titleCtrl.text.trim(),
                    'office': officeLocCtrl.text.trim(),
                    'email': emailCtrl.text.trim().isEmpty ? 'contact@uni.edu.tr' : emailCtrl.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  await FirebaseFirestore.instance.collection('instructors').doc(docId).set(newData, SetOptions(merge: true));
                  if (context.mounted) {
                    Navigator.pop(context);
                    _refreshAdminData(collectionKey: 'instructors');
                  }
                },
                child: const Text("Save"),
              )
            ],
          );
        },
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

                  final normalizedNewMealType = DataService.normalizeMealType(newMealName);

                  menus[normalizedNewMealType] = {
                    "menuName": menuNameCtrl.text.trim().isEmpty
                        ? normalizedNewMealType
                        : menuNameCtrl.text.trim(),
                    "time": timeCtrl.text.trim(),
                    "price": normalizedPrice,
                    "items": newItems,
                    "isChips": item['isChips'] ?? false,
                    "contentManuallyEdited": !DataService.isFixedCafeteriaMealType(normalizedNewMealType),
                    "templateAlgorithmVersion": item['templateAlgorithmVersion'] ?? 3,
                    "templateId": item['templateId'],
                    "templateRotationIndex": item['templateRotationIndex'],
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