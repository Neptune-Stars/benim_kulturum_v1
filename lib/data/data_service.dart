import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Same-session cache: prevents admin/student screens from re-reading
  // the same Firestore data after every tab click or rebuild.
  static Map<String, dynamic>? _databaseCache;
  static final Map<String, List<Map<String, dynamic>>> _collectionCache = {};
  static Map<String, dynamic>? _cafeteriaSettingsCache;
  static Map<String, int>? _dashboardSummaryCache;

  static const String defaultCampus = "Ataköy Campus";

  // Student-facing order. Breakfast and Fast Food are global/fixed menus;
  // only Meal is created as a daily Firestore document under cafeteriaMenus.
  static const List<String> cafeteriaMealTypes = [
    "Breakfast",
    "Meal",
    "Fast Food",
  ];

  static const List<String> fixedCafeteriaMealTypes = [
    "Breakfast",
    "Fast Food",
  ];

  static const List<String> dailyCafeteriaMealTypes = [
    "Meal",
  ];

  static const List<String> defaultPriceCategories = [
    "Beverages",
    "Coffee Varieties",
    "Toast Varieties",
    "Snacks",
  ];



  static const List<Map<String, String>> campusDirectoryCampuses = [
    {
      'key': 'Ataköy',
      'label': 'Ataköy Campus',
      'address': 'Istanbul Kultur University Ataköy Campus, E5 Highway Bakırköy 34158 Istanbul',
    },
    {
      'key': 'İncirli',
      'label': 'İncirli Campus',
      'address': 'Istanbul Kultur University İncirli Campus, Yolbaşı Street, 34147 Bakırköy Istanbul',
    },
    {
      'key': 'Şirinevler',
      'label': 'Şirinevler Campus',
      'address': 'Istanbul Kultur University Şirinevler Campus, E5 Highway No:22 Bahçelievler 34191 Istanbul',
    },
    {
      'key': 'Basın Ekspres',
      'label': 'Basın Ekspres Campus',
      'address': 'Istanbul Kultur University Basın Ekspres Campus, Halkalı Merkez District Basın Ekspres Avenue No:11 34303 Küçükçekmece Istanbul',
    },
  ];

  static const List<String> campusUnitCategories = [
    'All',
    'Academic Units',
    'Food & Beverage',
    'Study & Library',
    'Student Services',
    'Health & Security',
    'Halls & Event Spaces',
    'Other',
  ];

  static const List<String> campusUnitTypeOptions = [
    'Academic Unit',
    'Faculty',
    'Department',
    'Office',
    'Hall',
    'Auditorium',
    'Seminar Hall',
    'Conference Hall',
    'Food & Drink',
    'Cafeteria',
    'Cafe',
    'Restaurant',
    'Canteen',
    'Library',
    'Study Area',
    'Student Services',
    'Student Affairs',
    'Service',
    'Stationery',
    'Health Unit',
    'Infirmary',
    'Security',
    'Other',
  ];

  static String _searchNormalize(String? value) {
    return (value ?? '')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String normalizeCampusKey(String? rawCampus) {
    final value = _searchNormalize(rawCampus);
    if (value.isEmpty) return 'Ataköy';

    if (value.contains('atak')) return 'Ataköy';
    if (value.contains('incir')) return 'İncirli';
    if (value.contains('bas') || value.contains('ekspres') || value.contains('kucuk')) {
      return 'Basın Ekspres';
    }
    if (value.contains('sirin') || value.contains('bahcel')) return 'Şirinevler';

    return 'Ataköy';
  }

  static String campusDisplayName(String? rawCampus) {
    final key = normalizeCampusKey(rawCampus);
    final match = campusDirectoryCampuses.where((campus) => campus['key'] == key);
    return match.isEmpty ? '$key Campus' : match.first['label']!;
  }

  static String campusAddress(String? rawCampus) {
    final key = normalizeCampusKey(rawCampus);
    final match = campusDirectoryCampuses.where((campus) => campus['key'] == key);
    return match.isEmpty ? campusDisplayName(rawCampus) : match.first['address']!;
  }

  static String normalizeCampusUnitType(String? rawType) {
    final value = _searchNormalize(rawType).replaceAll('_', ' ').replaceAll('-', ' ');
    if (value.isEmpty) return 'Academic Unit';

    if (value.contains('faculty')) return 'Faculty';
    if (value.contains('department') || value.contains('school') || value.contains('academic')) {
      return 'Academic Unit';
    }
    if (value.contains('computer') && value.contains('lab')) return 'Computer Lab';
    if (value.contains('laboratory') || value == 'lab' || value.contains(' lab')) return 'Laboratory';
    if (value.contains('classroom') ||
        value.contains('lecture') ||
        value.contains('derslik') ||
        value.contains('sinif')) {
      return 'Classroom';
    }
    if (value.contains('amphitheater') || value.contains('amfi')) return 'Amphitheater';
    if (value.contains('workshop') || value.contains('factory')) return 'Workshop';
    if (value.contains('seminar')) return 'Seminar Hall';
    if (value.contains('conference')) return 'Conference Hall';
    if (value.contains('auditorium')) return 'Auditorium';
    if (value.contains('hall') || value.contains('courtroom')) return 'Hall';
    if (value.contains('cafeteria')) return 'Cafeteria';
    if (value.contains('cafe') || value.contains('coffee')) return 'Cafe';
    if (value.contains('restaurant')) return 'Restaurant';
    if (value.contains('canteen')) return 'Canteen';
    if (value.contains('food')) return 'Food & Drink';
    if (value.contains('library')) return 'Library';
    if (value.contains('study') || value.contains('workspace')) return 'Study Area';
    if (value.contains('student affairs') || value.contains('registrar')) return 'Student Affairs';
    if (value.contains('student service')) return 'Student Services';
    if (value.contains('stationery') || value.contains('copy')) return 'Stationery';
    if (value.contains('health') || value.contains('infirmary') || value.contains('revir')) return 'Health Unit';
    if (value.contains('security')) return 'Security';
    if (value.contains('office')) return 'Office';
    if (value.contains('service') || value.contains('bank') || value.contains('hairdresser')) return 'Service';

    return 'Other';
  }

  static bool isAcademicSpaceUnitType(String? rawType) {
    final value = _searchNormalize(rawType)
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    if (value.isEmpty) return false;

    return value.contains('classroom') ||
        value.contains('lecture hall') ||
        value.contains('lecture') ||
        value.contains('derslik') ||
        value.contains('sinif') ||
        value.contains('amphitheater') ||
        value.contains('amfi') ||
        value.contains('laboratory') ||
        value == 'lab' ||
        value.contains(' lab') ||
        value.contains('computer lab') ||
        value.contains('workshop');
  }

  static bool isAcademicSpaceUnitRecord(Map<dynamic, dynamic> unit) {
    final type = unit['type']?.toString();
    final typeNormalized = unit['typeNormalized']?.toString();
    final category = unit['category']?.toString();
    final name = unit['name']?.toString();
    final location = unit['location']?.toString();
    final roomCode = unit['roomCode']?.toString();

    return isAcademicSpaceUnitType(type) ||
        isAcademicSpaceUnitType(typeNormalized) ||
        isAcademicSpaceUnitType(category) ||
        isAcademicSpaceUnitType(name) ||
        isAcademicSpaceUnitType(location) ||
        isAcademicSpaceUnitType(roomCode);
  }

  static String campusUnitCategoryFromType(String? rawType) {
    final type = normalizeCampusUnitType(rawType);

    if (isAcademicSpaceUnitType(type)) {
      return 'Other';
    }

    switch (type) {
      case 'Faculty':
      case 'Department':
      case 'Academic Unit':
      case 'Office':
        return 'Academic Units';
      case 'Hall':
      case 'Auditorium':
      case 'Seminar Hall':
      case 'Conference Hall':
        return 'Halls & Event Spaces';
      case 'Food & Drink':
      case 'Cafeteria':
      case 'Cafe':
      case 'Restaurant':
      case 'Canteen':
        return 'Food & Beverage';
      case 'Library':
      case 'Study Area':
        return 'Study & Library';
      case 'Student Services':
      case 'Student Affairs':
      case 'Service':
      case 'Stationery':
        return 'Student Services';
      case 'Health Unit':
      case 'Infirmary':
      case 'Security':
        return 'Health & Security';
      default:
        return 'Other';
    }
  }

  static String campusUnitCategory(Map<dynamic, dynamic> unit) {
    final rawCategory = unit['category']?.toString().trim();
    if (rawCategory != null && rawCategory.isNotEmpty && campusUnitCategories.contains(rawCategory)) {
      return rawCategory;
    }
    return campusUnitCategoryFromType(unit['type']?.toString());
  }

  static bool isCampusUnitVisible(Map<dynamic, dynamic> unit) {
    if (unit['isVisible'] == false || unit['visible'] == false) return false;

    final status = _searchNormalize(unit['status']?.toString());
    if (status == 'hidden' || status == 'draft' || status == 'inactive') {
      return false;
    }

    // Unit/Campus Guide must not show classrooms, labs, amphitheaters,
    // lecture halls, workshops, or similar academic spaces.
    // Those belong only to the Classrooms screen.
    if (isAcademicSpaceUnitRecord(unit)) {
      return false;
    }

    return true;
  }

  static Map<String, dynamic> normalizeCampusUnitRecord(Map<dynamic, dynamic> rawUnit) {
    final unit = Map<String, dynamic>.from(rawUnit);
    final campusSource = unit['campus']?.toString().trim().isNotEmpty == true
        ? unit['campus']?.toString()
        : (unit['location']?.toString().split(',').first ?? unit['building']?.toString());
    final type = normalizeCampusUnitType(unit['type']?.toString());
    final category = campusUnitCategory(unit);

    unit['campusKey'] = normalizeCampusKey(campusSource);
    unit['campusDisplayName'] = campusDisplayName(campusSource);
    unit['typeNormalized'] = type;
    unit['category'] = category;
    unit['isVisible'] = isCampusUnitVisible(unit);
    unit['isFeatured'] = unit['isFeatured'] == true;
    unit['sortOrder'] = unit['sortOrder'] is int
        ? unit['sortOrder']
        : int.tryParse(unit['sortOrder']?.toString() ?? '') ?? 999;
    return unit;
  }

  static List<Map<String, dynamic>> normalizeCampusUnitList(List<Map<String, dynamic>> units) {
    final normalized = units.map(normalizeCampusUnitRecord).toList();
    normalized.sort((a, b) {
      final campusCompare = (a['campusKey'] ?? '').toString().compareTo((b['campusKey'] ?? '').toString());
      if (campusCompare != 0) return campusCompare;
      final orderCompare = (a['sortOrder'] as int).compareTo(b['sortOrder'] as int);
      if (orderCompare != 0) return orderCompare;
      return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
    });
    return normalized;
  }

  static void clearCache() {
    _databaseCache = null;
    _collectionCache.clear();
    _cafeteriaSettingsCache = null;
    _dashboardSummaryCache = null;
  }

  static void clearCollectionCache(String collectionName) {
    _collectionCache.remove(collectionName);
    _databaseCache = null;
    _dashboardSummaryCache = null;
  }

  static void clearCafeteriaCache() {
    _cafeteriaSettingsCache = null;
    _databaseCache = null;
  }

  static bool isDeletedRecord(Map<dynamic, dynamic> item) {
    final status = item['status']?.toString().trim().toLowerCase() ?? '';

    return item['isDeleted'] == true ||
        item['deleted'] == true ||
        status == 'deleted';
  }

  static Future<Map<String, dynamic>> loadDatabase({bool forceRefresh = false}) async {
    if (!forceRefresh && _databaseCache != null) {
      return _databaseCache!;
    }

    final results = await Future.wait([
      fetchCollection('buildings', forceRefresh: forceRefresh),
      fetchCollection('classrooms', forceRefresh: forceRefresh),
      fetchCollection('instructors', forceRefresh: forceRefresh),
      fetchCollection('events', forceRefresh: forceRefresh),
      fetchCollection('announcements', forceRefresh: forceRefresh),
      fetchCollection('prices', forceRefresh: forceRefresh),
      fetchCollection('issues', forceRefresh: forceRefresh),
      fetchCollection('students', forceRefresh: forceRefresh),
      fetchCollection('campuses', forceRefresh: forceRefresh),
      fetchCollection('classroomLocations', forceRefresh: forceRefresh),
    ]);

    _databaseCache = {
      'buildings': results[0],
      'classrooms': results[1],
      'instructors': results[2],
      'events': results[3],
      'announcements': results[4],
      'prices': results[5],
      'issues': results[6],
      'students': results[7],
      'campuses': results[8],
      'classroomLocations': results[9],
      'cafeteria': await fetchCafeteriaSettings(forceRefresh: forceRefresh),
    };

    return _databaseCache!;
  }

  static Future<List<Map<String, dynamic>>> fetchCollection(
      String collectionName, {
        bool forceRefresh = false,
        String? orderBy,
        bool descending = false,
        int? limit,
      }) async {
    final canUseCache = orderBy == null && limit == null;

    if (!forceRefresh && canUseCache && _collectionCache.containsKey(collectionName)) {
      return List<Map<String, dynamic>>.from(_collectionCache[collectionName]!);
    }

    Query<Map<String, dynamic>> query = _db.collection(collectionName);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final querySnapshot = await query.get();

    var rows = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['firestoreDocId'] = doc.id;
      return data;
    }).toList();

    if (collectionName == 'buildings') {
      rows = normalizeCampusUnitList(rows);
    }

    if (collectionName == 'announcements') {
      rows = rows.where((row) => !isDeletedRecord(row)).toList();
    }

    if (canUseCache) {
      _collectionCache[collectionName] = rows;
    }

    return rows;
  }

  static Future<void> deleteAnnouncement(String announcementId) async {
    final batch = _db.batch();

    final announcementRef = _db.collection('announcements').doc(announcementId);
    final notificationRef = _db.collection('notifications').doc('announcement_$announcementId');

    batch.delete(announcementRef);
    batch.delete(notificationRef);

    await batch.commit();

    clearCollectionCache('announcements');
    clearCollectionCache('notifications');
  }

  static Future<List<String>> fetchPriceCategories({bool forceRefresh = false}) async {
    final categoryDocs = await fetchCollection(
      'priceCategories',
      forceRefresh: forceRefresh,
    );

    final categories = <String>[];

    void addCategory(String? value) {
      final category = value?.trim();
      if (category == null || category.isEmpty) return;
      if (!categories.contains(category)) {
        categories.add(category);
      }
    }

    for (final category in defaultPriceCategories) {
      addCategory(category);
    }

    for (final doc in categoryDocs) {
      addCategory(
        doc['name']?.toString() ??
            doc['title']?.toString() ??
            doc['category']?.toString(),
      );
    }

    return categories;
  }

  static Future<void> addPriceCategory(String categoryName) async {
    final normalizedName = categoryName.trim();
    if (normalizedName.isEmpty) return;

    final docId = normalizedName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9ğüşöçıİĞÜŞÖÇ]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final safeDocId = docId.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : docId;

    await _db.collection('priceCategories').doc(safeDocId).set({
      'id': safeDocId,
      'name': normalizedName,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    clearCollectionCache('priceCategories');
  }


  static Future<void> deletePriceCategory(String categoryName) async {
    final normalizedName = categoryName.trim();
    if (normalizedName.isEmpty) return;

    final normalizedDocId = normalizedName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9ğüşöçıİĞÜŞÖÇ]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final safeDocId = normalizedDocId.isEmpty
        ? normalizedName
        : normalizedDocId;

    final categoryRef = _db.collection('priceCategories');
    final batch = _db.batch();

    // Delete the deterministic document id used by addPriceCategory().
    batch.delete(categoryRef.doc(safeDocId));

    // Also delete any legacy/duplicate category documents stored with the
    // same visible name but a different document id.
    final matchingDocs = await categoryRef
        .where('name', isEqualTo: normalizedName)
        .get();

    for (final doc in matchingDocs.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    clearCollectionCache('priceCategories');
  }

  static Future<Map<String, dynamic>> fetchCafeteriaSettings({bool forceRefresh = false}) async {
    if (!forceRefresh && _cafeteriaSettingsCache != null) {
      return Map<String, dynamic>.from(_cafeteriaSettingsCache!);
    }

    final cafeteriaDoc = await _db.collection('settings').doc('cafeteria').get();

    _cafeteriaSettingsCache = cafeteriaDoc.exists
        ? Map<String, dynamic>.from(cafeteriaDoc.data() ?? {})
        : <String, dynamic>{};

    return Map<String, dynamic>.from(_cafeteriaSettingsCache!);
  }

  static Future<Map<String, dynamic>> fetchAdminClassroomTabData({bool forceRefresh = false}) async {
    final results = await Future.wait([
      fetchCollection('classrooms', forceRefresh: forceRefresh),
      fetchCollection('campuses', forceRefresh: forceRefresh),
      fetchCollection('classroomLocations', forceRefresh: forceRefresh),
    ]);

    return {
      'classrooms': results[0],
      'campuses': results[1],
      'classroomLocations': results[2],
    };
  }

  static Future<Map<String, int>> fetchDashboardSummary({bool forceRefresh = false}) async {
    if (!forceRefresh && _dashboardSummaryCache != null) {
      return Map<String, int>.from(_dashboardSummaryCache!);
    }

    final entries = await Future.wait([
      _countCollectionEntry('buildings'),
      _countCollectionEntry('classrooms'),
      _countCollectionEntry('instructors'),
      _countCollectionEntry('events'),
      _countCollectionEntry('announcements'),
      _countCollectionEntry('cafeteriaMenus'),
      _countCollectionEntry('prices'),
      _countCollectionEntry('issues'),
      _countCollectionEntry('students'),
    ]);

    _dashboardSummaryCache = Map<String, int>.fromEntries(entries);
    return Map<String, int>.from(_dashboardSummaryCache!);
  }

  static Future<MapEntry<String, int>> _countCollectionEntry(String collectionName) async {
    try {
      final snapshot = await _db.collection(collectionName).count().get();
      return MapEntry(collectionName, snapshot.count ?? 0);
    } catch (_) {
      final rows = await fetchCollection(collectionName);
      return MapEntry(collectionName, rows.length);
    }
  }

  static Map<String, dynamic> defaultMenuForMealType(String mealType) {
    final normalizedMealType = normalizeMealType(mealType);

    return {
      "mealType": normalizedMealType,
      "menuName": normalizedMealType,
      "time": "",
      "price": normalizedMealType == "Fast Food" ? "Product based" : "",
      "items": <dynamic>[],
      "isChips": false,
      "isActive": false,
      "isActiveManuallyEdited": false,
    };
  }

  static List<dynamic> _cleanMenuItems(dynamic rawItems) {
    if (rawItems is! List) return <dynamic>[];

    return rawItems.where((item) {
      if (item is Map) {
        return item['name']?.toString().trim().isNotEmpty == true;
      }

      return item.toString().trim().isNotEmpty;
    }).map((item) {
      if (item is Map) {
        return {
          "name": item['name']?.toString().trim() ?? "",
          "price": item['price']?.toString().trim() ?? "",
        };
      }

      return item.toString().trim();
    }).toList();
  }

  static String normalizeMealType(String mealType) {
    final trimmed = mealType.trim();
    if (trimmed == "Lunch" || trimmed == "Dinner" || trimmed == "Menu of the Day") {
      return "Meal";
    }
    return trimmed;
  }

  static bool isFixedCafeteriaMealType(String mealType) {
    return fixedCafeteriaMealTypes.contains(normalizeMealType(mealType));
  }

  static bool isDailyCafeteriaMealType(String mealType) {
    return dailyCafeteriaMealTypes.contains(normalizeMealType(mealType));
  }

  static DateTime startOfWeek(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    return cleanDate.subtract(Duration(days: cleanDate.weekday - 1));
  }

  static bool isWeekend(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  static bool isSaturday(DateTime date) => date.weekday == DateTime.saturday;

  static bool isSunday(DateTime date) => date.weekday == DateTime.sunday;

  static bool defaultIsCafeteriaDayActive(DateTime date) {
    // Default weekly rule:
    // - Saturday: day is open, only Fast Food is active.
    // - Sunday: day is closed, no meal type is active.
    // - Weekdays: day is open, normal menu types are active.
    return !isSunday(date);
  }

  static bool defaultIsMenuActiveForDate(DateTime date, String mealType) {
    final normalizedMealType = normalizeMealType(mealType);

    if (isSunday(date)) {
      return false;
    }

    if (isSaturday(date)) {
      return normalizedMealType == "Fast Food";
    }

    return true;
  }

  static String defaultMealTypeForDate(DateTime date) {
    if (isSunday(date)) {
      return "Closed";
    }

    if (isSaturday(date)) {
      return "Fast Food";
    }

    return "Meal";
  }

  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  static String formatDisplayDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return "$d/$m/$y";
  }

  static String weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      case DateTime.saturday:
        return "Saturday";
      case DateTime.sunday:
        return "Sunday";
      default:
        return "Unknown";
    }
  }

  static String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String canonicalCampusKey(String campus) {
    final value = _slug(campus);

    if (value == 'atakoy' || value == 'atakoy_campus' || value == 'atakoy_yerleskesi') {
      return 'atakoy_campus';
    }
    if (value == 'incirli' || value == 'incirli_campus' || value == 'incirli_yerleskesi') {
      return 'incirli_campus';
    }
    if (value == 'sirinevler' || value == 'sirinevler_campus' || value == 'sirinevler_yerleskesi') {
      return 'sirinevler_campus';
    }
    if (value == 'basin_ekspres' || value == 'basin_ekspres_campus' || value == 'basin_ekspres_yerleskesi') {
      return 'basin_ekspres_campus';
    }

    return value.isEmpty ? 'atakoy_campus' : value;
  }

  static String canonicalCampusLabel(String campus) {
    switch (canonicalCampusKey(campus)) {
      case 'atakoy_campus':
        return 'Ataköy Campus';
      case 'incirli_campus':
        return 'İncirli Campus';
      case 'sirinevler_campus':
        return 'Şirinevler Campus';
      case 'basin_ekspres_campus':
        return 'Basın Ekspres Campus';
      default:
        return campus.trim().isEmpty ? defaultCampus : campus.trim();
    }
  }

  static String cafeteriaMenuDocId({
    required DateTime date,
    String campus = defaultCampus,
    required String mealType,
  }) {
    return "${formatDateKey(date)}_${canonicalCampusKey(campus)}_${_slug(normalizeMealType(mealType))}";
  }

  static String cafeteriaDayStatusDocId({
    required DateTime date,
    String campus = defaultCampus,
  }) {
    return "${formatDateKey(date)}_${canonicalCampusKey(campus)}";
  }

  static Map<String, dynamic> buildCafeteriaDayStatusDocument({
    required DateTime date,
    String campus = defaultCampus,
    bool? isDayActive,
  }) {
    final weekend = isWeekend(date);

    return {
      "id": cafeteriaDayStatusDocId(date: date, campus: campus),
      "date": formatDateKey(date),
      "displayDate": formatDisplayDate(date),
      "weekStart": formatDateKey(startOfWeek(date)),
      "weekday": weekdayName(date.weekday),
      "weekdayIndex": date.weekday,
      "campus": canonicalCampusLabel(campus),
      "campusKey": canonicalCampusKey(campus),
      "isWeekend": weekend,
      "isDayActive": isDayActive ?? defaultIsCafeteriaDayActive(date),
      "weekendDefaultRuleVersion": 2,
      "updatedAt": FieldValue.serverTimestamp(),
    };
  }

  static Future<Map<String, dynamic>> fetchCafeteriaDayStatus(
      DateTime date, {
        String campus = defaultCampus,
      }) async {
    final docId = cafeteriaDayStatusDocId(date: date, campus: campus);
    final doc = await _db.collection('cafeteriaDayStatuses').doc(docId).get();

    return doc.data() == null
        ? buildCafeteriaDayStatusDocument(date: date, campus: campus)
        : Map<String, dynamic>.from(doc.data()!);
  }

  static Future<void> setCafeteriaDayActiveStatus(
      DateTime date,
      bool isActive, {
        String campus = defaultCampus,
      }) async {
    final dayStatusId = cafeteriaDayStatusDocId(date: date, campus: campus);

    await _db.collection('cafeteriaDayStatuses').doc(dayStatusId).set(
      {
        ...buildCafeteriaDayStatusDocument(
          date: date,
          campus: campus,
          isDayActive: isActive,
        ),
        "isDayActiveManuallyEdited": true,
        "manualUpdatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final mealType in dailyCafeteriaMealTypes) {
      final menuDocId = cafeteriaMenuDocId(
        date: date,
        campus: campus,
        mealType: mealType,
      );

      await _db.collection('cafeteriaMenus').doc(menuDocId).set({
        "isDayActive": isActive,
        "dayStatusId": dayStatusId,
        "dayActiveManuallyEdited": true,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> setDailyMenuActiveStatus({
    required DateTime date,
    String campus = defaultCampus,
    required String mealType,
    required bool isActive,
  }) async {
    final normalizedMealType = normalizeMealType(mealType);

    if (isFixedCafeteriaMealType(normalizedMealType)) {
      await setFixedCafeteriaMenuActiveStatus(
        mealType: normalizedMealType,
        isActive: isActive,
      );
      return;
    }

    final docId = cafeteriaMenuDocId(
      date: date,
      campus: campus,
      mealType: normalizedMealType,
    );

    await _db.collection('cafeteriaMenus').doc(docId).set({
      "isActive": isActive,
      "isActiveManuallyEdited": true,
      "manualUpdatedAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setFixedCafeteriaMenuActiveStatus({
    required String mealType,
    required bool isActive,
  }) async {
    final normalizedMealType = normalizeMealType(mealType);
    final cafeteriaRef = _db.collection('settings').doc('cafeteria');
    final cafeteriaDoc = await cafeteriaRef.get();

    final currentData = cafeteriaDoc.data() == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(cafeteriaDoc.data()!);

    final menus = Map<String, dynamic>.from((currentData['menus'] as Map?) ?? {});
    final currentMenu = Map<String, dynamic>.from(
      (menus[normalizedMealType] as Map?) ?? defaultMenuForMealType(normalizedMealType),
    );

    currentMenu['mealType'] = normalizedMealType;
    currentMenu['isActive'] = isActive;
    currentMenu['isActiveManuallyEdited'] = true;
    currentMenu['manualUpdatedAt'] = FieldValue.serverTimestamp();

    menus[normalizedMealType] = currentMenu;

    final mealTypes = (currentData['mealTypes'] as List<dynamic>?)
        ?.map((e) => normalizeMealType(e.toString()))
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList() ??
        <String>[];

    if (!mealTypes.contains(normalizedMealType)) {
      mealTypes.add(normalizedMealType);
    }

    await cafeteriaRef.set({
      "mealTypes": mealTypes,
      "menus": menus,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    clearCafeteriaCache();
  }

  static Future<void> saveCafeteriaMenu({
    required DateTime date,
    String campus = defaultCampus,
    required String mealType,
    required Map<String, dynamic> menu,
  }) async {
    final normalizedMealType = normalizeMealType(mealType);

    if (isFixedCafeteriaMealType(normalizedMealType)) {
      final cafeteriaRef = _db.collection('settings').doc('cafeteria');
      final cafeteriaDoc = await cafeteriaRef.get();

      final currentData = cafeteriaDoc.data() == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(cafeteriaDoc.data()!);

      final menus = Map<String, dynamic>.from((currentData['menus'] as Map?) ?? {});
      final currentMenu = Map<String, dynamic>.from(
        (menus[normalizedMealType] as Map?) ?? defaultMenuForMealType(normalizedMealType),
      );

      final completedMenu = {
        ...currentMenu,
        ...menu,
        "mealType": normalizedMealType,
        "items": _cleanMenuItems(menu['items'] ?? currentMenu['items']),
        "isActive": menu['isActive'] ?? currentMenu['isActive'] ?? true,
        "isActiveManuallyEdited": menu['isActiveManuallyEdited'] == true ||
            currentMenu['isActiveManuallyEdited'] == true,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      menus[normalizedMealType] = completedMenu;

      final mealTypes = (currentData['mealTypes'] as List<dynamic>?)
          ?.map((e) => normalizeMealType(e.toString()))
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList() ??
          <String>[];

      if (!mealTypes.contains(normalizedMealType)) {
        mealTypes.add(normalizedMealType);
      }

      await cafeteriaRef.set({
        "mealTypes": mealTypes,
        "menus": menus,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      clearCafeteriaCache();
      return;
    }

    final dayStatus = await fetchCafeteriaDayStatus(date, campus: campus);
    final docId = cafeteriaMenuDocId(
      date: date,
      campus: campus,
      mealType: normalizedMealType,
    );

    final docRef = _db.collection('cafeteriaMenus').doc(docId);
    final existingDoc = await docRef.get();

    final existingData = existingDoc.data() == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(existingDoc.data()!);

    final dailyMenu = {
      ...existingData,
      ...menu,
      "mealType": normalizedMealType,
      "items": _cleanMenuItems(menu['items'] ?? existingData['items']),
      "contentManuallyEdited": true,
    };

    await docRef.set(
      buildCafeteriaMenuDocument(
        date: date,
        campus: campus,
        mealType: normalizedMealType,
        menu: dailyMenu,
        includeCreatedAt: !existingDoc.exists,
        isDayActive: dayStatus['isDayActive'] != false,
      ),
      SetOptions(merge: true),
    );
  }

  static Map<String, dynamic> buildCafeteriaMenuDocument({
    required DateTime date,
    String campus = defaultCampus,
    required String mealType,
    required Map<String, dynamic> menu,
    bool includeCreatedAt = false,
    bool? isDayActive,
  }) {
    final normalizedMealType = normalizeMealType(mealType);
    final cleanedItems = _cleanMenuItems(menu['items']);

    final hasRealContent = cleanedItems.isNotEmpty;
    final requestedActive = menu['isActive'] == true;

    final data = <String, dynamic>{
      "id": cafeteriaMenuDocId(date: date, campus: campus, mealType: normalizedMealType),
      "date": formatDateKey(date),
      "displayDate": formatDisplayDate(date),
      "weekStart": formatDateKey(startOfWeek(date)),
      "weekday": weekdayName(date.weekday),
      "weekdayIndex": date.weekday,
      "campus": canonicalCampusLabel(campus),
      "campusKey": canonicalCampusKey(campus),
      "mealType": normalizedMealType,
      "menuName": menu['menuName']?.toString().trim().isNotEmpty == true
          ? menu['menuName'].toString().trim()
          : normalizedMealType,
      "time": menu['time']?.toString().trim() ?? "",
      "price": menu['price']?.toString().trim() ?? "",
      "items": cleanedItems,
      "isChips": menu['isChips'] == true,
      "isWeekend": isWeekend(date),
      "dayStatusId": cafeteriaDayStatusDocId(date: date, campus: campus),
      "isDayActive": isDayActive ?? menu['isDayActive'] ?? defaultIsCafeteriaDayActive(date),
      "isActive": (isDayActive ?? menu['isDayActive'] ?? defaultIsCafeteriaDayActive(date)) == true &&
          hasRealContent &&
          requestedActive,
      "isActiveManuallyEdited": menu['isActiveManuallyEdited'] == true ||
          menu['manualActiveOverride'] == true,
      "contentManuallyEdited": menu['contentManuallyEdited'] == true,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (menu['createdAt'] != null) {
      data["createdAt"] = menu['createdAt'];
    }

    if (includeCreatedAt && menu['createdAt'] == null) {
      data["createdAt"] = FieldValue.serverTimestamp();
    }

    return data;
  }

  static Map<String, dynamic> _fixedCafeteriaMenuDocument({
    required DateTime date,
    required String campus,
    required String mealType,
    required Map<String, dynamic> settingsData,
    required bool isDayActive,
  }) {
    final normalizedMealType = normalizeMealType(mealType);
    final settingsMenus = Map<String, dynamic>.from((settingsData['menus'] as Map?) ?? {});
    final settingsMenu = Map<String, dynamic>.from(
      (settingsMenus[normalizedMealType] as Map?) ?? defaultMenuForMealType(normalizedMealType),
    );

    final doc = buildCafeteriaMenuDocument(
      date: date,
      campus: campus,
      mealType: normalizedMealType,
      menu: settingsMenu,
      isDayActive: isDayActive,
    );

    doc['isFixedMenu'] = true;
    doc['storageScope'] = 'global_settings';

    return doc;
  }

  static Map<String, Map<String, dynamic>> _composeCafeteriaMenusForDate({
    required DateTime date,
    required String campus,
    required Map<String, dynamic> settingsData,
    required Map<String, dynamic> dayStatus,
    Map<String, dynamic>? dailyMealData,
  }) {
    final isDayActive = dayStatus['isDayActive'] != false;
    final menus = <String, Map<String, dynamic>>{};

    menus['Breakfast'] = _fixedCafeteriaMenuDocument(
      date: date,
      campus: campus,
      mealType: 'Breakfast',
      settingsData: settingsData,
      isDayActive: isDayActive,
    );

    menus['Meal'] = buildCafeteriaMenuDocument(
      date: date,
      campus: campus,
      mealType: 'Meal',
      menu: dailyMealData == null || dailyMealData.isEmpty
          ? defaultMenuForMealType('Meal')
          : Map<String, dynamic>.from(dailyMealData),
      isDayActive: isDayActive,
    )..addAll({
      'isFixedMenu': false,
      'storageScope': 'daily_document',
    });

    menus['Fast Food'] = _fixedCafeteriaMenuDocument(
      date: date,
      campus: campus,
      mealType: 'Fast Food',
      settingsData: settingsData,
      isDayActive: isDayActive,
    );

    return menus;
  }

  static Stream<Map<String, dynamic>> cafeteriaMenusForDateStream(
      DateTime date, {
        String campus = defaultCampus,
      }) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final controller = StreamController<Map<String, dynamic>>();

    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? daySubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? settingsSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? mealSubscription;

    Map<String, dynamic>? dayStatus;
    Map<String, dynamic>? settingsData;
    Map<String, dynamic>? dailyMealData;

    var dayReady = false;
    var settingsReady = false;
    var mealReady = false;

    void emitIfReady() {
      if (controller.isClosed || !dayReady || !settingsReady || !mealReady) {
        return;
      }

      final resolvedDayStatus = dayStatus ??
          buildCafeteriaDayStatusDocument(
            date: cleanDate,
            campus: campus,
          );

      final resolvedSettings = settingsData ?? <String, dynamic>{};

      final menus = _composeCafeteriaMenusForDate(
        date: cleanDate,
        campus: campus,
        settingsData: resolvedSettings,
        dayStatus: resolvedDayStatus,
        dailyMealData: dailyMealData,
      );

      controller.add({
        'date': cleanDate,
        'dateKey': formatDateKey(cleanDate),
        'displayDate': formatDisplayDate(cleanDate),
        'weekday': weekdayName(cleanDate.weekday),
        'weekdayIndex': cleanDate.weekday,
        'campus': canonicalCampusLabel(campus),
        'campusKey': canonicalCampusKey(campus),
        'isWeekend': isWeekend(cleanDate),
        'isDayActive': resolvedDayStatus['isDayActive'] != false,
        'dayStatus': resolvedDayStatus,
        'menus': menus,
      });
    }

    Future<void> start() async {
      try {
        final dayStatusId = cafeteriaDayStatusDocId(
          date: cleanDate,
          campus: campus,
        );

        final mealDocId = cafeteriaMenuDocId(
          date: cleanDate,
          campus: campus,
          mealType: 'Meal',
        );

        daySubscription = _db
            .collection('cafeteriaDayStatuses')
            .doc(dayStatusId)
            .snapshots()
            .listen((snapshot) {
          dayReady = true;
          dayStatus = snapshot.data() == null
              ? buildCafeteriaDayStatusDocument(
            date: cleanDate,
            campus: campus,
          )
              : Map<String, dynamic>.from(snapshot.data()!);
          emitIfReady();
        }, onError: controller.addError);

        settingsSubscription = _db
            .collection('settings')
            .doc('cafeteria')
            .snapshots()
            .listen((snapshot) {
          settingsReady = true;
          settingsData = snapshot.data() == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(snapshot.data()!);
          emitIfReady();
        }, onError: controller.addError);

        mealSubscription = _db
            .collection('cafeteriaMenus')
            .doc(mealDocId)
            .snapshots()
            .listen((snapshot) {
          mealReady = true;
          dailyMealData = snapshot.data() == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(snapshot.data()!);
          emitIfReady();
        }, onError: controller.addError);
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    start();

    controller.onCancel = () async {
      await daySubscription?.cancel();
      await settingsSubscription?.cancel();
      await mealSubscription?.cancel();
    };

    return controller.stream;
  }

  static Future<Map<String, Map<String, dynamic>>> fetchDailyCafeteriaMenus(
      DateTime date, {
        String campus = defaultCampus,
      }) async {
    final dayStatus = await fetchCafeteriaDayStatus(date, campus: campus);
    final settingsData = await fetchCafeteriaSettings(forceRefresh: true);

    final mealDocId = cafeteriaMenuDocId(
      date: date,
      campus: campus,
      mealType: 'Meal',
    );

    final mealDoc = await _db.collection('cafeteriaMenus').doc(mealDocId).get();

    return _composeCafeteriaMenusForDate(
      date: date,
      campus: campus,
      settingsData: settingsData,
      dayStatus: dayStatus,
      dailyMealData: mealDoc.data() == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(mealDoc.data()!),
    );
  }

  static Future<List<Map<String, dynamic>>> fetchWeeklyCafeteriaMenus({
    DateTime? weekStart,
    String campus = defaultCampus,
  }) async {
    final start = startOfWeek(weekStart ?? DateTime.now());
    final settingsData = await fetchCafeteriaSettings(forceRefresh: true);
    final days = <Map<String, dynamic>>[];

    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final dayStatus = await fetchCafeteriaDayStatus(date, campus: campus);

      final mealDocId = cafeteriaMenuDocId(
        date: date,
        campus: campus,
        mealType: 'Meal',
      );

      final mealDoc = await _db.collection('cafeteriaMenus').doc(mealDocId).get();

      final menus = _composeCafeteriaMenusForDate(
        date: date,
        campus: campus,
        settingsData: settingsData,
        dayStatus: dayStatus,
        dailyMealData: mealDoc.data() == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(mealDoc.data()!),
      );

      days.add({
        "date": date,
        "dateKey": formatDateKey(date),
        "displayDate": formatDisplayDate(date),
        "weekday": weekdayName(date.weekday),
        "weekdayIndex": date.weekday,
        "campus": canonicalCampusLabel(campus),
        "campusKey": canonicalCampusKey(campus),
        "isWeekend": isWeekend(date),
        "isDayActive": dayStatus['isDayActive'] != false,
        "dayStatus": dayStatus,
        "menus": menus,
      });
    }

    return days;
  }

  static Stream<Map<String, dynamic>> todayDashboardMenuStream({
    String campus = defaultCampus,
  }) {
    final today = DateTime.now();

    return cafeteriaMenusForDateStream(today, campus: campus).map((dayData) {
      final isDayActive = dayData['isDayActive'] != false;

      if (!isDayActive) {
        return {
          "menuName": "No Cafeteria Service Today",
          "mealType": "Closed",
          "time": "-",
          "price": "-",
          "items": <dynamic>[],
          "isDayActive": false,
          "isActive": false,
          "dashboardMode": "day_closed",
          "dashboardMessage": "Cafeteria or Fast Food service is not active today.",
        };
      }

      final menusByType = Map<String, Map<String, dynamic>>.from(
        (dayData['menus'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map)),
            ) ??
            {},
      );

      final priority = isWeekend(today)
          ? <String>["Fast Food"]
          : <String>["Meal", "Fast Food", "Breakfast"];

      for (final mealType in priority) {
        final data = menusByType[mealType];
        final visible = data != null &&
            data['isDayActive'] != false &&
            data['isActive'] != false;

        if (visible) {
          final result = Map<String, dynamic>.from(data);
          result['dashboardMode'] = isWeekend(today) ? 'weekend_fastfood' : 'weekday_meal';
          result['dashboardMessage'] = isWeekend(today)
              ? 'Today is the weekend. Active Fast Food options are displayed.'
              : 'Today is a weekday. Active campus menu is displayed.';
          return result;
        }
      }

      return {
        "menuName": "No Menu Available Today",
        "mealType": "Closed",
        "time": "-",
        "price": "-",
        "items": <dynamic>[],
        "isDayActive": true,
        "isActive": false,
        "dashboardMode": "no_active_menu",
        "dashboardMessage": "There is no active menu for today.",
      };
    });
  }

}