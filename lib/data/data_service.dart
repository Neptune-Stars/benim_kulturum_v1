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
  static Future<void>? _defaultDataInitializationFuture;
  static bool _defaultDataChecked = false;

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
    'Classrooms & Labs',
    'Halls & Event Spaces',
    'Food & Beverage',
    'Study & Library',
    'Student Services',
    'Health & Security',
    'Other',
  ];

  static const List<String> campusUnitTypeOptions = [
    'Academic Unit',
    'Faculty',
    'Department',
    'Office',
    'Classroom',
    'Laboratory',
    'Computer Lab',
    'Workshop',
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
    if (value.contains('classroom') || value.contains('lecture')) return 'Classroom';
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

  static String campusUnitCategoryFromType(String? rawType) {
    final type = normalizeCampusUnitType(rawType);
    switch (type) {
      case 'Faculty':
      case 'Department':
      case 'Academic Unit':
      case 'Office':
        return 'Academic Units';
      case 'Classroom':
      case 'Laboratory':
      case 'Computer Lab':
      case 'Workshop':
        return 'Classrooms & Labs';
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
    if (status == 'hidden' || status == 'draft' || status == 'inactive') return false;
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

  static Future<void> initializeDefaultDataIfNeeded() async {
    if (_defaultDataChecked) {
      return;
    }

    _defaultDataInitializationFuture ??= _initializeDefaultDataInternal();
    await _defaultDataInitializationFuture;
  }

  static Future<void> _initializeDefaultDataInternal() async {
    final studentSnap = await _db.collection('students').limit(1).get();
    if (studentSnap.docs.isEmpty) {
      print("Students missing, loading default data to Firebase...");
      await _seedExtraData();
      clearCollectionCache('students');
    }

    final campusSnap = await _db.collection('campuses').limit(1).get();
    if (campusSnap.docs.isEmpty) {
      print("Campus reference data missing, loading to Firebase...");
      await _seedCampusReferenceData();
      clearCollectionCache('campuses');
      clearCollectionCache('classroomLocations');
    }

    await ensureCafeteriaData();
    _defaultDataChecked = true;
  }

  static Future<Map<String, dynamic>> loadDatabase({bool forceRefresh = false}) async {
    if (!forceRefresh && _databaseCache != null) {
      return _databaseCache!;
    }

    await initializeDefaultDataIfNeeded();

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

    await initializeDefaultDataIfNeeded();

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

    if (canUseCache) {
      _collectionCache[collectionName] = rows;
    }

    return rows;
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


  static String _demoPriceCategoryKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', ' ')
        .replaceAll('/', ' ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String _demoPriceDocId(String category, String name) {
    final raw = '${category}_$name';
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('&', ' ')
        .replaceAll('/', ' ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// One-time demo seed for the Prices screen.
  ///
  /// Use this only once before the presentation, then remove the temporary
  /// call from main.dart. If you leave it active, every app launch will reset
  /// admin price changes.
  static Future<void> resetDemoPricesForPresentation() async {
    final categoriesToRemove = <String>{
      'food',
      'tea_coffee',
      'tea_and_coffee',
      'tea_coffe',
    };

    final categoriesToReset = <String>{
      'beverages',
      'coffee_varieties',
      'toast_varieties',
      'snacks',
      ...categoriesToRemove,
    };

    final defaultCategories = <Map<String, dynamic>>[
      {
        'id': 'beverages',
        'name': 'Beverages',
        'order': 1,
        'isDefault': true,
      },
      {
        'id': 'coffee_varieties',
        'name': 'Coffee Varieties',
        'order': 2,
        'isDefault': true,
      },
      {
        'id': 'toast_varieties',
        'name': 'Toast Varieties',
        'order': 3,
        'isDefault': true,
      },
      {
        'id': 'snacks',
        'name': 'Snacks',
        'order': 4,
        'isDefault': true,
      },
    ];

    final realisticPrices = <Map<String, dynamic>>[
      // Beverages
      {
        'name': 'Water 500 ml',
        'price': '₺15',
        'category': 'Beverages',
      },
      {
        'name': 'Sparkling Water',
        'price': '₺20',
        'category': 'Beverages',
      },
      {
        'name': 'Ayran',
        'price': '₺25',
        'category': 'Beverages',
      },
      {
        'name': 'Fruit Juice',
        'price': '₺35',
        'category': 'Beverages',
      },
      {
        'name': 'Iced Tea',
        'price': '₺40',
        'category': 'Beverages',
      },
      {
        'name': 'Cola',
        'price': '₺45',
        'category': 'Beverages',
      },
      {
        'name': 'Fanta',
        'price': '₺45',
        'category': 'Beverages',
      },
      {
        'name': 'Sprite',
        'price': '₺45',
        'category': 'Beverages',
      },

      // Coffee Varieties
      {
        'name': 'Turkish Tea',
        'price': '₺15',
        'category': 'Coffee Varieties',
      },
      {
        'name': 'Turkish Coffee',
        'price': '₺45',
        'category': 'Coffee Varieties',
      },
      {
        'name': 'Espresso',
        'price': '₺45',
        'category': 'Coffee Varieties',
      },
      {
        'name': 'Filter Coffee',
        'price': '₺55',
        'category': 'Coffee Varieties',
      },
      {
        'name': 'Americano',
        'price': '₺60',
        'category': 'Coffee Varieties',
      },
      {
        'name': 'Latte',
        'price': '₺70',
        'category': 'Coffee Varieties',
      },
      {
        'name': 'Cappuccino',
        'price': '₺70',
        'category': 'Coffee Varieties',
      },
      {
        'name': 'Mocha',
        'price': '₺80',
        'category': 'Coffee Varieties',
      },

      // Toast Varieties
      {
        'name': 'Cheese Toast',
        'price': '₺70',
        'category': 'Toast Varieties',
      },
      {
        'name': 'Sucuk Toast',
        'price': '₺90',
        'category': 'Toast Varieties',
      },
      {
        'name': 'Mixed Toast',
        'price': '₺100',
        'category': 'Toast Varieties',
      },
      {
        'name': 'Ayvalık Toast',
        'price': '₺130',
        'category': 'Toast Varieties',
      },
      {
        'name': 'Chicken Sandwich',
        'price': '₺120',
        'category': 'Toast Varieties',
      },
      {
        'name': 'Tuna Sandwich',
        'price': '₺130',
        'category': 'Toast Varieties',
      },

      // Snacks
      {
        'name': 'Simit',
        'price': '₺20',
        'category': 'Snacks',
      },
      {
        'name': 'Poğaça',
        'price': '₺30',
        'category': 'Snacks',
      },
      {
        'name': 'Açma',
        'price': '₺30',
        'category': 'Snacks',
      },
      {
        'name': 'Croissant',
        'price': '₺60',
        'category': 'Snacks',
      },
      {
        'name': 'Muffin',
        'price': '₺55',
        'category': 'Snacks',
      },
      {
        'name': 'Chocolate Bar',
        'price': '₺40',
        'category': 'Snacks',
      },
      {
        'name': 'Chips',
        'price': '₺50',
        'category': 'Snacks',
      },
      {
        'name': 'Biscuit',
        'price': '₺35',
        'category': 'Snacks',
      },
      {
        'name': 'Cake Slice',
        'price': '₺70',
        'category': 'Snacks',
      },
    ];

    final batch = _db.batch();

    final priceDocs = await _db.collection('prices').get();
    for (final doc in priceDocs.docs) {
      final data = doc.data();
      final category = data['category']?.toString() ?? '';
      final categoryKey = _demoPriceCategoryKey(category);

      if (categoriesToReset.contains(categoryKey)) {
        batch.delete(doc.reference);
      }
    }

    final categoryDocs = await _db.collection('priceCategories').get();
    for (final doc in categoryDocs.docs) {
      final data = doc.data();
      final name = data['name']?.toString() ??
          data['title']?.toString() ??
          data['category']?.toString() ??
          '';
      final categoryKey = _demoPriceCategoryKey(name);

      if (categoriesToRemove.contains(categoryKey)) {
        batch.delete(doc.reference);
      }
    }

    for (final category in defaultCategories) {
      final id = category['id'].toString();

      batch.set(
        _db.collection('priceCategories').doc(id),
        {
          ...category,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    for (final item in realisticPrices) {
      final category = item['category'].toString();
      final name = item['name'].toString();
      final docId = _demoPriceDocId(category, name);

      batch.set(
        _db.collection('prices').doc(docId),
        {
          'id': docId,
          'name': name,
          'price': item['price'],
          'category': category,
          'isActive': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    clearCollectionCache('prices');
    clearCollectionCache('priceCategories');
  }

  static Future<List<Map<String, dynamic>>> _fetchList(String collectionName) {
    return fetchCollection(collectionName);
  }

  static Future<Map<String, dynamic>> fetchCafeteriaSettings({bool forceRefresh = false}) async {
    if (!forceRefresh && _cafeteriaSettingsCache != null) {
      return Map<String, dynamic>.from(_cafeteriaSettingsCache!);
    }

    await initializeDefaultDataIfNeeded();
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

    await initializeDefaultDataIfNeeded();

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

  static Map<String, dynamic> _defaultCafeteriaData() {
    return {
      "mealTypes": cafeteriaMealTypes,
      "defaultCampus": defaultCampus,
      "weekdayDefaultMealType": "Meal",
      "weekendDefaultMealType": "Fast Food",
      "menus": {
        "Breakfast": {
          "menuName": "Breakfast Menu",
          "time": "08:00-10:00",
          "price": "₺25",
          "items": [
            "Cheese",
            "Olives",
            "Tomatoes",
            "Cucumber",
            "Jam",
            "Butter",
            "Boiled egg",
            "Tea"
          ],
          "isChips": true,
        },
        "Meal": {
          "menuName": "Today's Meal",
          "time": "13:00-18:00",
          "price": "₺175",
          "items": [
            "Lentil Soup",
            "Chicken Schnitzel",
            "Rice",
            "Seasonal Salad",
            "Ayran"
          ],
          "isChips": false,
        },
        "Fast Food": {
          "menuName": "Fast Food Menu",
          "time": "10:00-18:00",
          "price": "Product based",
          "items": [
            {"name": "Grilled Meatball Menu", "price": "₺75"},
            {"name": "Chicken Schnitzel Menu", "price": "₺70"},
            {"name": "Penne Pasta", "price": "₺55"},
            {"name": "French Fries", "price": "₺35"},
            {"name": "Cheese Toast", "price": "₺40"}
          ],
          "isChips": false,
        },
      },
      "updatedAt": FieldValue.serverTimestamp(),
    };
  }

  static Future<void> ensureCafeteriaData() async {
    final cafeteriaRef = _db.collection('settings').doc('cafeteria');
    final cafeteriaDoc = await cafeteriaRef.get();

    final defaultData = _defaultCafeteriaData();

    if (!cafeteriaDoc.exists || cafeteriaDoc.data() == null) {
      await cafeteriaRef.set(defaultData);
      clearCafeteriaCache();
      print("Cafeteria data created for the first time.");
      return;
    }

    final currentData = Map<String, dynamic>.from(cafeteriaDoc.data()!);

    final currentMealTypes = (currentData['mealTypes'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    final currentMenus =
    Map<String, dynamic>.from((currentData['menus'] as Map?) ?? {});

    final defaultMenus =
    Map<String, dynamic>.from(defaultData['menus'] as Map);

    final Map<String, dynamic> fixedMenus = {};

    fixedMenus["Breakfast"] = _mergeMenu(
      defaultMenus["Breakfast"],
      currentMenus["Breakfast"],
      fallbackMenuName: "Breakfast Menu",
    );

    final existingFoodMenu = currentMenus["Meal"] ?? currentMenus["Lunch"];

    fixedMenus["Meal"] = _mergeMenu(
      defaultMenus["Meal"],
      existingFoodMenu,
      fallbackMenuName: "Today's Meal",
    );

    fixedMenus["Fast Food"] = _mergeMenu(
      defaultMenus["Fast Food"],
      currentMenus["Fast Food"],
      fallbackMenuName: "Fast Food Menu",
      itemsHavePrices: true,
    );

    final fixedMealTypes = <String>[
      "Breakfast",
      "Meal",
      "Fast Food",
    ];

    // Admin can add custom categories later, they will be preserved.
    for (final mealType in currentMealTypes) {
      if (mealType == "Lunch" ||
          mealType == "Dinner" ||
          mealType == "Menu of the Day") {
        continue;
      }

      if (!fixedMealTypes.contains(mealType)) {
        fixedMealTypes.add(mealType);

        if (currentMenus[mealType] is Map) {
          fixedMenus[mealType] = currentMenus[mealType];
        }
      }
    }

    await cafeteriaRef.set({
      "mealTypes": fixedMealTypes,
      "defaultCampus": currentData['defaultCampus'] ?? defaultCampus,
      "weekdayDefaultMealType": currentData['weekdayDefaultMealType'] ?? "Meal",
      "weekendDefaultMealType": currentData['weekendDefaultMealType'] ?? "Fast Food",
      "menus": fixedMenus,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    clearCafeteriaCache();
    print("Cafeteria data checked and missing parts fixed.");
  }

  static Map<String, dynamic> _mergeMenu(
      dynamic defaultMenu,
      dynamic existingMenu, {
        required String fallbackMenuName,
        String? forcedTime,
        bool itemsHavePrices = false,
      }) {
    final defaultMap = Map<String, dynamic>.from((defaultMenu as Map?) ?? {});
    final existingMap = Map<String, dynamic>.from((existingMenu as Map?) ?? {});

    final merged = {
      ...defaultMap,
      ...existingMap,
    };

    final menuName = merged["menuName"]?.toString().trim() ?? "";
    merged["menuName"] = menuName.isNotEmpty ? menuName : fallbackMenuName;

    if (forcedTime != null) {
      merged["time"] = forcedTime;
    } else {
      final time = merged["time"]?.toString().trim() ?? "";
      merged["time"] = time.isNotEmpty ? time : defaultMap["time"];
    }

    final price = merged["price"]?.toString().trim() ?? "";
    merged["price"] = price.isNotEmpty ? price : defaultMap["price"];

    if (itemsHavePrices) {
      merged["price"] = "Product based";
      merged["items"] = _normalizePricedItems(
        merged["items"],
        defaultMap["items"],
      );
    } else if (merged["items"] is! List || (merged["items"] as List).isEmpty) {
      merged["items"] = defaultMap["items"] ?? [];
    }

    merged["isChips"] = merged["isChips"] ?? false;

    return merged;
  }

  static List<Map<String, dynamic>> _normalizePricedItems(
      dynamic currentItems,
      dynamic defaultItems,
      ) {
    final defaults = <String, String>{};

    if (defaultItems is List) {
      for (final item in defaultItems) {
        if (item is Map) {
          final name = item["name"]?.toString().trim() ?? "";
          final price = item["price"]?.toString().trim() ?? "";
          if (name.isNotEmpty) {
            defaults[name] = price.isNotEmpty ? price : "₺0";
          }
        }
      }
    }

    final sourceItems = currentItems is List && currentItems.isNotEmpty
        ? currentItems
        : (defaultItems is List ? defaultItems : <dynamic>[]);

    return sourceItems
        .map<Map<String, dynamic>>((item) {
      if (item is Map) {
        final name = item["name"]?.toString().trim() ?? "";
        final price = item["price"]?.toString().trim() ?? "";

        return {
          "name": name,
          "price": price.isNotEmpty ? price : (defaults[name] ?? "₺0"),
        };
      }

      final name = item.toString().trim();
      return {
        "name": name,
        "price": defaults[name] ?? "₺0",
      };
    })
        .where((item) => item["name"].toString().trim().isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> defaultMenuForMealType(String mealType) {
    final defaultMenus =
    Map<String, dynamic>.from(_defaultCafeteriaData()['menus'] as Map);

    final normalizedMealType = normalizeMealType(mealType);
    return Map<String, dynamic>.from(
      (defaultMenus[normalizedMealType] ?? defaultMenus['Meal']) as Map,
    );
  }

  static List<Map<String, dynamic>> _mealTemplateRotation() {
    return [
      {
        "templateId": "meal_menu_01",
        "menuName": "Today's Meal",
        "items": [
          "Ezogelin Soup",
          "Chicken Schnitzel",
          "Rice Pilaf",
          "Seasonal Salad",
          "Ayran",
        ],
      },
      {
        "templateId": "meal_menu_02",
        "menuName": "Today's Meal",
        "items": [
          "Tomato Soup",
          "Grilled Meatballs",
          "Bulgur Pilaf",
          "Yogurt",
          "Fruit",
        ],
      },
      {
        "templateId": "meal_menu_03",
        "menuName": "Today's Meal",
        "items": [
          "Lentil Soup",
          "Chicken Saute",
          "Pasta",
          "Mixed Salad",
          "Ayran",
        ],
      },
      {
        "templateId": "meal_menu_04",
        "menuName": "Today's Meal",
        "items": [
          "Vegetable Soup",
          "Doner Plate",
          "Rice Pilaf",
          "Cacık",
          "Dessert",
        ],
      },
      {
        "templateId": "meal_menu_05",
        "menuName": "Today's Meal",
        "items": [
          "Tarhana Soup",
          "Baked Chicken",
          "Pasta",
          "Seasonal Salad",
          "Ayran",
        ],
      },
      {
        "templateId": "meal_menu_06",
        "menuName": "Today's Meal",
        "items": [
          "Yayla Soup",
          "Beef Stew",
          "Rice Pilaf",
          "Pickles",
          "Compote",
        ],
      },
      {
        "templateId": "meal_menu_07",
        "menuName": "Today's Meal",
        "items": [
          "Mushroom Soup",
          "Chicken Curry",
          "Noodles",
          "Green Salad",
          "Ayran",
        ],
      },
      {
        "templateId": "meal_menu_08",
        "menuName": "Today's Meal",
        "items": [
          "Mercimek Soup",
          "Izmir Meatballs",
          "Bulgur Pilaf",
          "Yogurt",
          "Fruit",
        ],
      },
      {
        "templateId": "meal_menu_09",
        "menuName": "Today's Meal",
        "items": [
          "Chicken Soup",
          "Pasta with Tomato Sauce",
          "Crispy Chicken",
          "Seasonal Salad",
          "Ayran",
        ],
      },
      {
        "templateId": "meal_menu_10",
        "menuName": "Today's Meal",
        "items": [
          "Soup of the Day",
          "Roasted Chicken",
          "Rice Pilaf",
          "Cacık",
          "Dessert",
        ],
      },
    ];
  }

  static int _daysSinceRotationStart(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final rotationStart = DateTime(2026, 5, 4);
    return cleanDate.difference(rotationStart).inDays;
  }

  static Map<String, dynamic> defaultDailyMealForDate(DateTime date) {
    final base = defaultMenuForMealType('Meal');
    final templates = _mealTemplateRotation();

    if (isSunday(date)) {
      return {
        ...base,
        "templateId": "cafeteria_closed",
        "templateRotationIndex": -1,
        "templateAlgorithmVersion": 3,
        "menuName": "Cafeteria Closed",
        "time": base["time"] ?? "13:00-18:00",
        "price": "₺175",
        "items": <String>["Cafeteria Closed"],
        "isChips": false,
        "contentManuallyEdited": false,
      };
    }

    if (isSaturday(date)) {
      return {
        ...base,
        "templateId": "weekend_fast_food_only",
        "templateRotationIndex": -1,
        "templateAlgorithmVersion": 3,
        "menuName": "Weekend Fast Food Service",
        "time": base["time"] ?? "13:00-18:00",
        "price": "₺175",
        "items": <String>["Weekend Fast Food Service"],
        "isChips": false,
        "contentManuallyEdited": false,
      };
    }

    final rawIndex = _daysSinceRotationStart(date);
    final rotationIndex = rawIndex < 0
        ? (templates.length - ((-rawIndex) % templates.length)) % templates.length
        : rawIndex % templates.length;
    final selected = templates[rotationIndex];

    return {
      ...base,
      "templateId": selected["templateId"],
      "templateRotationIndex": rotationIndex,
      "templateAlgorithmVersion": 3,
      "menuName": selected["menuName"] ?? "Today's Meal",
      "time": base["time"] ?? "13:00-18:00",
      "price": "₺175",
      "items": List<String>.from(selected["items"] as List),
      "isChips": false,
      "contentManuallyEdited": false,
    };
  }

  static List<String> _plainMenuItems(dynamic value) {
    if (value is! List) return <String>[];

    return value
        .map((item) {
          if (item is Map) return item['name']?.toString() ?? '';
          return item.toString();
        })
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static bool _samePlainMenuItems(dynamic a, dynamic b) {
    final left = _plainMenuItems(a);
    final right = _plainMenuItems(b);
    if (left.length != right.length) return false;
    for (int i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  static bool _isLegacySeedMealContent(dynamic items) {
    return _samePlainMenuItems(items, [
      "Lentil Soup",
      "Chicken Schnitzel",
      "Rice",
      "Seasonal Salad",
      "Ayran",
    ]);
  }

  static bool _shouldPreserveExistingDailyMeal(Map<String, dynamic> currentMenu) {
    final items = currentMenu['items'];
    final hasItems = _plainMenuItems(items).isNotEmpty;
    if (!hasItems) return false;

    final wasGeneratedByOldAlgorithm =
        currentMenu['templateAlgorithmVersion'] != null &&
        currentMenu['templateAlgorithmVersion'] != 3;
    final hasOldDemoPrice = currentMenu['price']?.toString().trim() == '₺35';

    if (_isLegacySeedMealContent(items) || wasGeneratedByOldAlgorithm || hasOldDemoPrice) {
      return false;
    }

    // Non-empty, non-legacy content is treated as real menu content.
    // This preserves dates that were edited directly from Firestore before
    // the contentManuallyEdited flag existed.
    return true;
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
    await ensureCafeteriaDayStatus(date, campus: campus);

    final docId = cafeteriaDayStatusDocId(date: date, campus: campus);
    final doc = await _db.collection('cafeteriaDayStatuses').doc(docId).get();

    return doc.data() == null
        ? buildCafeteriaDayStatusDocument(date: date, campus: campus)
        : Map<String, dynamic>.from(doc.data()!);
  }

  static Future<void> ensureCafeteriaDayStatus(
      DateTime date, {
        String campus = defaultCampus,
      }) async {
    final docId = cafeteriaDayStatusDocId(date: date, campus: campus);
    final docRef = _db.collection('cafeteriaDayStatuses').doc(docId);
    final doc = await docRef.get();

    final defaultDayActive = defaultIsCafeteriaDayActive(date);

    if (!doc.exists || doc.data() == null) {
      await docRef.set(
        buildCafeteriaDayStatusDocument(
          date: date,
          campus: campus,
          isDayActive: defaultDayActive,
        )..addAll({
          "createdAt": FieldValue.serverTimestamp(),
          "isDayActiveManuallyEdited": false,
        }),
      );
      return;
    }

    final current = Map<String, dynamic>.from(doc.data()!);
    final isManuallyEdited = current['isDayActiveManuallyEdited'] == true ||
        current['manualOverride'] == true;
    final resolvedDayActive = isManuallyEdited
        ? current['isDayActive'] != false
        : defaultDayActive;

    await docRef.set({
      ...buildCafeteriaDayStatusDocument(
        date: date,
        campus: campus,
        isDayActive: resolvedDayActive,
      ),
      "createdAt": current['createdAt'],
      "isDayActiveManuallyEdited": isManuallyEdited,
    }, SetOptions(merge: true));
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
        ? _defaultCafeteriaData()
        : Map<String, dynamic>.from(cafeteriaDoc.data()!);

    final menus = Map<String, dynamic>.from((currentData['menus'] as Map?) ?? {});
    final currentMenu = Map<String, dynamic>.from(
      (menus[normalizedMealType] as Map?) ?? defaultMenuForMealType(normalizedMealType),
    );

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

    for (final type in cafeteriaMealTypes) {
      if (!mealTypes.contains(type)) {
        mealTypes.add(type);
      }
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
          ? _defaultCafeteriaData()
          : Map<String, dynamic>.from(cafeteriaDoc.data()!);

      final menus = Map<String, dynamic>.from((currentData['menus'] as Map?) ?? {});
      final defaultMenu = defaultMenuForMealType(normalizedMealType);
      final completedMenu = _mergeMenu(
        defaultMenu,
        {
          ...Map<String, dynamic>.from((menus[normalizedMealType] as Map?) ?? {}),
          ...menu,
        },
        fallbackMenuName: defaultMenu['menuName']?.toString() ?? normalizedMealType,
        itemsHavePrices: normalizedMealType == "Fast Food",
      );

      completedMenu['isActive'] = menu['isActive'] ?? completedMenu['isActive'] ?? true;
      completedMenu['isActiveManuallyEdited'] = menu['isActiveManuallyEdited'] == true ||
          completedMenu['isActiveManuallyEdited'] == true;
      completedMenu['updatedAt'] = FieldValue.serverTimestamp();

      menus[normalizedMealType] = completedMenu;

      final mealTypes = (currentData['mealTypes'] as List<dynamic>?)
              ?.map((e) => normalizeMealType(e.toString()))
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList() ??
          <String>[];

      for (final type in cafeteriaMealTypes) {
        if (!mealTypes.contains(type)) {
          mealTypes.add(type);
        }
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
    final dailyMenu = {
      ...menu,
      "contentManuallyEdited": true,
      "templateAlgorithmVersion": menu["templateAlgorithmVersion"] ?? 3,
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
    final defaultMenu = defaultMenuForMealType(normalizedMealType);
    final completedMenu = _mergeMenu(
      defaultMenu,
      menu,
      fallbackMenuName: defaultMenu['menuName']?.toString() ?? normalizedMealType,
      itemsHavePrices: normalizedMealType == "Fast Food",
    );

    final dayStatusId = cafeteriaDayStatusDocId(date: date, campus: campus);
    final visibleByDefault = defaultIsMenuActiveForDate(date, normalizedMealType);
    final isActiveManuallyEdited = menu['isActiveManuallyEdited'] == true ||
        menu['manualActiveOverride'] == true;
    final resolvedIsActive = isActiveManuallyEdited
        ? menu['isActive'] ?? visibleByDefault
        : visibleByDefault;

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
      "menuName": completedMenu['menuName'],
      "time": completedMenu['time'],
      "price": completedMenu['price'],
      "items": completedMenu['items'],
      "isChips": completedMenu['isChips'] ?? false,
      "isWeekend": isWeekend(date),
      "dayStatusId": dayStatusId,
      "isDayActive": isDayActive ?? menu['isDayActive'] ?? defaultIsCafeteriaDayActive(date),
      "isActive": resolvedIsActive,
      "isActiveManuallyEdited": isActiveManuallyEdited,
      "contentManuallyEdited": menu['contentManuallyEdited'] == true,
      "templateId": menu['templateId'],
      "templateRotationIndex": menu['templateRotationIndex'],
      "templateAlgorithmVersion": menu['templateAlgorithmVersion'] ?? (normalizedMealType == "Meal" ? 3 : null),
      "weekendDefaultRuleVersion": 2,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (includeCreatedAt) {
      data["createdAt"] = FieldValue.serverTimestamp();
    }

    return data;
  }

  static Future<void> ensureDailyCafeteriaMenus(
      DateTime date, {
        String campus = defaultCampus,
      }) async {
    await ensureCafeteriaData();
    await ensureCafeteriaDayStatus(date, campus: campus);

    final dayStatus = await fetchCafeteriaDayStatus(date, campus: campus);
    final isDayActive = dayStatus['isDayActive'] != false;

    for (final mealType in dailyCafeteriaMealTypes) {
      final docId = cafeteriaMenuDocId(date: date, campus: campus, mealType: mealType);
      final docRef = _db.collection('cafeteriaMenus').doc(docId);
      final doc = await docRef.get();
      final generatedMenu = defaultDailyMealForDate(date);

      if (!doc.exists || doc.data() == null) {
        await docRef.set(
          buildCafeteriaMenuDocument(
            date: date,
            campus: campus,
            mealType: mealType,
            menu: generatedMenu,
            includeCreatedAt: true,
            isDayActive: isDayActive,
          ),
        );
      } else {
        final currentMenu = Map<String, dynamic>.from(doc.data()!);
        final preserveExistingMeal = _shouldPreserveExistingDailyMeal(currentMenu);
        final sourceMenu = preserveExistingMeal
            ? currentMenu
            : {
                ...generatedMenu,
                "createdAt": currentMenu["createdAt"],
                "isActive": currentMenu["isActive"],
                "isActiveManuallyEdited": currentMenu["isActiveManuallyEdited"] == true,
                "contentManuallyEdited": false,
              };

        await docRef.set(
          buildCafeteriaMenuDocument(
            date: date,
            campus: campus,
            mealType: mealType,
            menu: sourceMenu,
            isDayActive: isDayActive,
          ),
          SetOptions(merge: true),
        );
      }
    }
  }

  static Future<void> ensureWeeklyCafeteriaMenus({
    DateTime? weekStart,
    String campus = defaultCampus,
  }) async {
    final start = startOfWeek(weekStart ?? DateTime.now());

    for (int i = 0; i < 7; i++) {
      await ensureDailyCafeteriaMenus(start.add(Duration(days: i)), campus: campus);
    }
  }

  static Future<void> migrateCafeteriaDailyMealDataForPresentation({
    DateTime? referenceDate,
    String campus = defaultCampus,
    int weeksBefore = 2,
    int weeksAfter = 8,
  }) async {
    final reference = referenceDate ?? DateTime.now();
    final start = startOfWeek(reference).subtract(Duration(days: 7 * weeksBefore));
    final totalDays = 7 * (weeksBefore + weeksAfter + 1);

    for (int i = 0; i < totalDays; i++) {
      await ensureDailyCafeteriaMenus(start.add(Duration(days: i)), campus: campus);
    }

    clearCafeteriaCache();
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
    final defaultMenu = defaultMenuForMealType(normalizedMealType);
    final settingsMenu = Map<String, dynamic>.from(
      (settingsMenus[normalizedMealType] as Map?) ?? defaultMenu,
    );

    final doc = buildCafeteriaMenuDocument(
      date: date,
      campus: campus,
      mealType: normalizedMealType,
      menu: settingsMenu,
      isDayActive: isDayActive,
    );

    final fixedMenuIsActive = settingsMenu['isActive'] != false;
    doc['isActive'] = isDayActive &&
        defaultIsMenuActiveForDate(date, normalizedMealType) &&
        fixedMenuIsActive;
    doc['isActiveManuallyEdited'] = settingsMenu['isActiveManuallyEdited'] == true;
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

    final mealSource = dailyMealData == null || dailyMealData.isEmpty
        ? defaultDailyMealForDate(date)
        : Map<String, dynamic>.from(dailyMealData);

    menus['Meal'] = buildCafeteriaMenuDocument(
      date: date,
      campus: campus,
      mealType: 'Meal',
      menu: mealSource,
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

      final resolvedSettings = settingsData ?? _defaultCafeteriaData();

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
        await ensureDailyCafeteriaMenus(cleanDate, campus: campus);

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
              ? _defaultCafeteriaData()
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
    await ensureDailyCafeteriaMenus(date, campus: campus);

    final dayStatus = await fetchCafeteriaDayStatus(date, campus: campus);
    final settingsData = await fetchCafeteriaSettings(forceRefresh: true);
    final mealDocId = cafeteriaMenuDocId(date: date, campus: campus, mealType: 'Meal');
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

    // Only daily Meal documents are ensured here. Breakfast and Fast Food are
    // read from settings/cafeteria so global updates appear on every day.
    await ensureWeeklyCafeteriaMenus(weekStart: start, campus: campus);

    final settingsData = await fetchCafeteriaSettings(forceRefresh: true);
    final days = <Map<String, dynamic>>[];

    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final dayStatus = await fetchCafeteriaDayStatus(date, campus: campus);
      final mealDocId = cafeteriaMenuDocId(date: date, campus: campus, mealType: 'Meal');
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

  static Future<void> _seedCafeteriaData() async {
    await _db.collection('settings').doc('cafeteria').set(
      _defaultCafeteriaData(),
    );
  }

  static Future<void> _seedExtraData() async {
    final List<Map<String, dynamic>> starterPrices = [
      {"id": 1, "name": "Tea", "price": "₺3", "category": "Beverages"},
      {"id": 2, "name": "Turkish Coffee", "price": "₺12", "category": "Coffee Varieties"},
      {"id": 3, "name": "Ayran", "price": "₺5", "category": "Beverages"},
      {"id": 4, "name": "Toast", "price": "₺15", "category": "Toast Varieties"},
      {"id": 5, "name": "Today's Meal", "price": "₺175", "category": "Meal"},
    ];

    for (final item in starterPrices) {
      await _db.collection('prices').doc(item['id'].toString()).set(item);
    }

    final List<Map<String, dynamic>> starterIssues = [
      {
        "id": 1,
        "category": "Infrastructure Issue",
        "priority": "High",
        "subject": "Projector not working in the classroom",
        "location": "MF-101",
        "description": "No image is displayed when the computer is connected.",
        "date": "Today 10:30",
        "status": "Open",
        "createdAt": FieldValue.serverTimestamp(),
        "resolvedAt": null,
      },
      {
        "id": 2,
        "category": "Cleaning",
        "priority": "Medium",
        "subject": "Out of soap in the restrooms",
        "location": "FEAS 2nd Floor",
        "description": "The liquid soap dispensers in the men's restroom are completely empty.",
        "date": "Yesterday 14:15",
        "status": "Open",
        "createdAt": FieldValue.serverTimestamp(),
        "resolvedAt": null,
      },
    ];

    for (final item in starterIssues) {
      await _db.collection('issues').doc(item['id'].toString()).set(item);
    }

    final List<Map<String, dynamic>> starterStudents = [
      {
        "id": 1,
        "name": "Sample Student",
        "no": "20210001234",
        "email": "student@uni.edu.tr",
        "password": "123456",
        "grade": "3rd Grade",
      },
      {
        "id": 2,
        "name": "Ayşe Demir",
        "no": "20220005678",
        "email": "ayse@uni.edu.tr",
        "password": "password123",
        "grade": "2nd Grade",
      },
    ];

    for (final item in starterStudents) {
      await _db.collection('students').doc(item['id'].toString()).set(item);
    }
  }

  // Firebase-backed dropdown reference data for classroom admin form.
  static Future<void> _seedCampusReferenceData() async {
    final List<Map<String, dynamic>> campuses = [
      {
        "id": "atakoy",
        "name": "Ataköy",
        "displayName": "Ataköy Campus",
        "officialGroup": "Bakırköy Campus",
        "sortOrder": 1,
      },
      {
        "id": "incirli",
        "name": "İncirli",
        "displayName": "İncirli Campus",
        "officialGroup": "Bakırköy Campus",
        "sortOrder": 2,
      },
      {
        "id": "sirin_evler",
        "name": "Şirinevler",
        "displayName": "Şirinevler / Bahçelievler Campus",
        "officialGroup": "Bahçelievler Campus",
        "sortOrder": 3,
      },
      {
        "id": "basin_ekspres",
        "name": "Basın Ekspres",
        "displayName": "Basın Ekspres / Küçükçekmece Campus",
        "officialGroup": "Küçükçekmece Campus",
        "sortOrder": 4,
      },
    ];

    for (final campus in campuses) {
      await _db.collection('campuses').doc(campus['id'].toString()).set(campus);
    }

    final List<Map<String, dynamic>> classroomLocations = [
      {
        "id": "atakoy_bina",
        "campusId": "atakoy",
        "campusName": "Ataköy Campus",
        "name": "Ataköy Building",
        "type": "building",
        "sortOrder": 1,
      },
      {
        "id": "atakoy_muhendislik",
        "campusId": "atakoy",
        "campusName": "Ataköy Campus",
        "name": "Faculty of Engineering",
        "type": "faculty",
        "sortOrder": 2,
      },
      {
        "id": "atakoy_mimarlik",
        "campusId": "atakoy",
        "campusName": "Ataköy Campus",
        "name": "Faculty of Architecture",
        "type": "faculty",
        "sortOrder": 3,
      },
      {
        "id": "atakoy_sanat_tasarim",
        "campusId": "atakoy",
        "campusName": "Ataköy Campus",
        "name": "Faculty of Art and Design",
        "type": "faculty",
        "sortOrder": 4,
      },
      {
        "id": "atakoy_fen_edebiyat",
        "campusId": "atakoy",
        "campusName": "Ataköy Campus",
        "name": "Faculty of Arts and Sciences",
        "type": "faculty",
        "sortOrder": 5,
      },
      {
        "id": "incirli_bina",
        "campusId": "incirli",
        "campusName": "İncirli Campus",
        "name": "İncirli Building",
        "type": "building",
        "sortOrder": 1,
      },
      {
        "id": "incirli_myo",
        "campusId": "incirli",
        "campusName": "İncirli Campus",
        "name": "Vocational School",
        "type": "school",
        "sortOrder": 2,
      },
      {
        "id": "sirin_evler_bina",
        "campusId": "sirin_evler",
        "campusName": "Şirinevler / Bahçelievler Campus",
        "name": "Şirinevler Building",
        "type": "building",
        "sortOrder": 1,
      },
      {
        "id": "sirin_evler_hukuk",
        "campusId": "sirin_evler",
        "campusName": "Şirinevler / Bahçelievler Campus",
        "name": "Faculty of Law",
        "type": "faculty",
        "sortOrder": 2,
      },
      {
        "id": "sirin_evler_saglik",
        "campusId": "sirin_evler",
        "campusName": "Şirinevler / Bahçelievler Campus",
        "name": "Faculty of Health Sciences",
        "type": "faculty",
        "sortOrder": 3,
      },
      {
        "id": "sirin_evler_yabanci_diller",
        "campusId": "sirin_evler",
        "campusName": "Şirinevler / Bahçelievler Campus",
        "name": "Foreign Languages",
        "type": "unit",
        "sortOrder": 4,
      },
      {
        "id": "basin_ekspres_bina",
        "campusId": "basin_ekspres",
        "campusName": "Basın Ekspres / Küçükçekmece Campus",
        "name": "Basın Ekspres Building",
        "type": "building",
        "sortOrder": 1,
      },
      {
        "id": "basin_ekspres_egitim",
        "campusId": "basin_ekspres",
        "campusName": "Basın Ekspres / Küçükçekmece Campus",
        "name": "Faculty of Education",
        "type": "faculty",
        "sortOrder": 2,
      },
      {
        "id": "basin_ekspres_iibf",
        "campusId": "basin_ekspres",
        "campusName": "Basın Ekspres / Küçükçekmece Campus",
        "name": "Faculty of Economics and Admin. Sciences",
        "type": "faculty",
        "sortOrder": 3,
      },
    ];

    for (final location in classroomLocations) {
      await _db
          .collection('classroomLocations')
          .doc(location['id'].toString())
          .set(location);
    }
  }


  static Future<void> resetDemoCampusUnitsForPresentation() async {
    final demoUnits = <Map<String, dynamic>>[
      {
        'id': 910001,
        'name': 'Kültür Noktası / Student Dean’s Office',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Main Building, 4th Floor, Room 4G09',
        'building': 'Main Building',
        'floor': '4th Floor',
        'roomCode': '4G09',
        'possibleCorridor': 'G',
        'type': 'Student Services',
        'abbr': 'KN',
        'navigationHint': 'Main Building, 4th floor, room 4G09. Corridor G is inferred from the room code and should be verified on site.',
        'verificationStatus': 'room_verified_corridor_unverified',
        'needsVerification': true,
        'sortOrder': 1,
      },
      {
        'id': 910002,
        'name': 'Akıngüç Auditorium and Art Center',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Ataköy Building',
        'building': 'Ataköy Building',
        'floor': null,
        'roomCode': null,
        'type': 'Auditorium',
        'abbr': 'AKG',
        'navigationHint': 'Located inside Ataköy Building. Floor information should be verified on site.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 2,
      },
      {
        'id': 910003,
        'name': 'Önder Öztunalı Conference Hall',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Ataköy Building',
        'building': 'Ataköy Building',
        'floor': null,
        'roomCode': null,
        'type': 'Hall',
        'abbr': 'OO',
        'navigationHint': 'Located inside Ataköy Building. Floor information should be verified on site.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 3,
      },
      {
        'id': 910004,
        'name': 'Erdal İnönü Seminar Hall',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Ataköy Building',
        'building': 'Ataköy Building',
        'floor': null,
        'roomCode': null,
        'type': 'Hall',
        'abbr': 'EI',
        'navigationHint': 'Located inside Ataköy Building. Floor information should be verified on site.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 4,
      },
      {
        'id': 910005,
        'name': 'Seminar Hall II',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Ataköy Building',
        'building': 'Ataköy Building',
        'floor': null,
        'roomCode': null,
        'type': 'Hall',
        'abbr': 'SS2',
        'navigationHint': 'Located inside Ataköy Building. Floor information should be verified on site.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 5,
      },
      {
        'id': 910006,
        'name': '1st Floor Multipurpose Hall',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Ataköy Building, 1st Floor',
        'building': 'Ataköy Building',
        'floor': '1st Floor',
        'roomCode': null,
        'type': 'Hall',
        'abbr': '1CAS',
        'navigationHint': 'Ataköy Building, 1st floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 6,
      },
      {
        'id': 910007,
        'name': '2nd Floor Multipurpose / Seminar Hall',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Ataköy Building, 2nd Floor',
        'building': 'Ataköy Building',
        'floor': '2nd Floor',
        'roomCode': null,
        'type': 'Hall',
        'abbr': '2CAS',
        'navigationHint': 'Ataköy Building, 2nd floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 7,
      },
      {
        'id': 910008,
        'name': '4th Floor Multipurpose / Seminar Hall',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Ataköy Building, 4th Floor',
        'building': 'Ataköy Building',
        'floor': '4th Floor',
        'roomCode': null,
        'type': 'Hall',
        'abbr': '4CAS',
        'navigationHint': 'Ataköy Building, 4th floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 8,
      },
      {
        'id': 910009,
        'name': 'Design Factory',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Ataköy Building',
        'building': 'Ataköy Building',
        'floor': null,
        'roomCode': null,
        'type': 'Workshop',
        'abbr': 'TF',
        'navigationHint': 'Located at Ataköy Campus. Floor information should be verified on site.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 9,
      },
      {
        'id': 910010,
        'name': 'Ataköy Library',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus',
        'building': 'Ataköy Campus',
        'floor': null,
        'roomCode': null,
        'type': 'Library',
        'abbr': 'LIB',
        'navigationHint': 'Ataköy Campus library. Floor and corridor information should be verified on site.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 10,
      },
      {
        'id': 910011,
        'name': 'Health Unit / Infirmary',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, MIII Building, Ground Floor',
        'building': 'MIII Building',
        'floor': 'Ground Floor',
        'roomCode': null,
        'type': 'Health Unit',
        'abbr': 'REV',
        'navigationHint': 'MIII Building, ground floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 11,
      },
      {
        'id': 910012,
        'name': 'Canopy Cafe',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Ground Floor',
        'building': 'Ataköy Campus',
        'floor': 'Ground Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'CAN',
        'navigationHint': 'Ataköy Campus, ground floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 12,
      },
      {
        'id': 910013,
        'name': 'Terrace Cafe',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Ground Floor',
        'building': 'Ataköy Campus',
        'floor': 'Ground Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'TER',
        'navigationHint': 'Ataköy Campus, ground floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 13,
      },
      {
        'id': 910014,
        'name': 'Akpaz VIP',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, 6th Floor',
        'building': 'Ataköy Campus',
        'floor': '6th Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'VIP',
        'navigationHint': 'Ataköy Campus, 6th floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 14,
      },
      {
        'id': 910015,
        'name': 'B1/B2 Restaurant',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, B1 and B2 Floors',
        'building': 'Ataköy Campus',
        'floor': 'B1-B2',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'B12',
        'navigationHint': 'Ataköy Campus, B1 and B2 floors.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 15,
      },
      {
        'id': 910016,
        'name': 'Starbucks',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, B1 Floor',
        'building': 'Ataköy Campus',
        'floor': 'B1',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'SB',
        'navigationHint': 'Ataköy Campus, B1 floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 16,
      },
      {
        'id': 910017,
        'name': 'Ekspresso Lab / Cafe',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, B1 Floor',
        'building': 'Ataköy Campus',
        'floor': 'B1',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'EL',
        'navigationHint': 'Ataköy Campus, B1 floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 17,
      },
      {
        'id': 910018,
        'name': 'İş Bank Branch',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, B1 Floor',
        'building': 'Ataköy Campus',
        'floor': 'B1',
        'roomCode': null,
        'type': 'Service',
        'abbr': 'ISB',
        'navigationHint': 'Ataköy Campus, B1 floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 18,
      },
      {
        'id': 910019,
        'name': 'Gözde Stationery',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, B1 Floor',
        'building': 'Ataköy Campus',
        'floor': 'B1',
        'roomCode': null,
        'type': 'Service',
        'abbr': 'GK',
        'navigationHint': 'Ataköy Campus, B1 floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 19,
      },
      {
        'id': 910020,
        'name': 'Hairdresser',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, B1 Floor',
        'building': 'Ataköy Campus',
        'floor': 'B1',
        'roomCode': null,
        'type': 'Service',
        'abbr': 'KUA',
        'navigationHint': 'Ataköy Campus, B1 floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 20,
      },
      {
        'id': 910021,
        'name': 'Security Point',
        'campus': 'Ataköy',
        'location': 'Ataköy Campus, Main Entrance / Information Desk',
        'building': 'Main Entrance',
        'floor': null,
        'roomCode': null,
        'type': 'Security',
        'abbr': 'SEC',
        'navigationHint': 'Please go to the main entrance or information/security point.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 21,
      },
      {
        'id': 920001,
        'name': 'Faculty of Law',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Faculty of Law',
        'building': 'Faculty of Law',
        'floor': null,
        'roomCode': null,
        'type': 'Academic Unit',
        'abbr': 'HF',
        'navigationHint': 'Şirinevler / Bahçelievler Campus, Faculty of Law building.',
        'verificationStatus': 'building_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 1,
      },
      {
        'id': 920002,
        'name': 'Faculty of Health Sciences',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Faculty of Health Sciences',
        'building': 'Faculty of Health Sciences',
        'floor': null,
        'roomCode': null,
        'type': 'Academic Unit',
        'abbr': 'SBF',
        'navigationHint': 'Şirinevler / Bahçelievler Campus, Faculty of Health Sciences.',
        'verificationStatus': 'building_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 2,
      },
      {
        'id': 920003,
        'name': 'Vocational School of Justice',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Vocational School of Justice',
        'building': 'Vocational School of Justice',
        'floor': null,
        'roomCode': null,
        'type': 'Academic Unit',
        'abbr': 'AMYO',
        'navigationHint': 'Şirinevler / Bahçelievler Campus, Vocational School of Justice.',
        'verificationStatus': 'building_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 3,
      },
      {
        'id': 920004,
        'name': 'Foreign Languages Department',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Foreign Languages Department',
        'building': 'Foreign Languages Department',
        'floor': null,
        'roomCode': null,
        'type': 'Academic Unit',
        'abbr': 'YD',
        'navigationHint': 'Şirinevler / Bahçelievler Campus, Foreign Languages Department.',
        'verificationStatus': 'building_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 4,
      },
      {
        'id': 920005,
        'name': 'Moot Courtroom',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Faculty of Law, 6th Floor',
        'building': 'Faculty of Law',
        'floor': '6th Floor',
        'roomCode': null,
        'type': 'Hall',
        'abbr': 'KDS',
        'navigationHint': 'Faculty of Law, 6th floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 5,
      },
      {
        'id': 920006,
        'name': 'Faculty of Law Twin Hall',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Faculty of Law, 6th Floor',
        'building': 'Faculty of Law',
        'floor': '6th Floor',
        'roomCode': null,
        'type': 'Hall',
        'abbr': 'IKZ',
        'navigationHint': 'Faculty of Law, 6th floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 6,
      },
      {
        'id': 920007,
        'name': 'Faculty of Law Academic Offices',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Faculty of Law, 5th Floor, Rooms H-501 / H-502',
        'building': 'Faculty of Law',
        'floor': '5th Floor',
        'roomCode': 'H-501 / H-502',
        'type': 'Office',
        'abbr': 'HOF',
        'navigationHint': 'Faculty of Law, 5th floor, H-501 / H-502 room area.',
        'verificationStatus': 'room_verified',
        'needsVerification': false,
        'sortOrder': 7,
      },
      {
        'id': 920008,
        'name': 'Vocational School of Justice Classroom 302',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, 3rd Floor, Classroom 302',
        'building': 'Vocational School of Justice',
        'floor': '3rd Floor',
        'roomCode': '302',
        'type': 'Classroom',
        'abbr': '302',
        'navigationHint': 'Vocational School of Justice area, 3rd floor, classroom 302.',
        'verificationStatus': 'room_verified',
        'needsVerification': false,
        'sortOrder': 8,
      },
      {
        'id': 920009,
        'name': 'Faculty of Health Sciences Block C Classrooms',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Block C, 1st Floor, Classroom 1 / Classroom 2',
        'building': 'Block C',
        'floor': '1st Floor',
        'roomCode': 'Classroom 1 / Classroom 2',
        'type': 'Classroom',
        'abbr': 'C1',
        'navigationHint': 'Block C, 1st floor, Classroom 1 / Classroom 2.',
        'verificationStatus': 'room_verified',
        'needsVerification': false,
        'sortOrder': 9,
      },
      {
        'id': 920010,
        'name': 'Block C Chemistry Laboratory',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Block C, Chemistry Laboratory',
        'building': 'Block C',
        'floor': null,
        'roomCode': 'KİMYALAB',
        'type': 'Laboratory',
        'abbr': 'KIM',
        'navigationHint': 'Block C Chemistry Laboratory. Floor information should be verified on site.',
        'verificationStatus': 'room_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 10,
      },
      {
        'id': 920011,
        'name': 'Law Canteen',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Ground Floor',
        'building': 'Faculty of Law',
        'floor': 'Ground Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'HK',
        'navigationHint': 'Faculty of Law area, ground floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 11,
      },
      {
        'id': 920012,
        'name': 'Preparatory School Canteen',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Mezzanine Floor',
        'building': 'Preparatory / Foreign Languages Area',
        'floor': 'Mezzanine Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'HZK',
        'navigationHint': 'Preparatory area, mezzanine floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 12,
      },
      {
        'id': 920013,
        'name': 'Makarna Restaurant',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Ground Floor',
        'building': 'Şirinevler Campus',
        'floor': 'Ground Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'MR',
        'navigationHint': 'Şirinevler Campus, ground floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 13,
      },
      {
        'id': 920014,
        'name': 'Block C Restaurant',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Block C, 2nd Floor',
        'building': 'Block C',
        'floor': '2nd Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'CBR',
        'navigationHint': 'Block C, 2nd floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 14,
      },
      {
        'id': 920015,
        'name': 'Şirinevler VIP',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Block C, 6th Floor',
        'building': 'Block C',
        'floor': '6th Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'SVIP',
        'navigationHint': 'Block C, 6th floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 15,
      },
      {
        'id': 920016,
        'name': 'Security Point',
        'campus': 'Şirinevler',
        'location': 'Şirinevler / Bahçelievler Campus, Main Entrance / Information Desk',
        'building': 'Main Entrance',
        'floor': null,
        'roomCode': null,
        'type': 'Security',
        'abbr': 'SEC',
        'navigationHint': 'Please go to the main entrance or information/security point.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 16,
      },
      {
        'id': 930001,
        'name': 'Vocational School / MYO',
        'campus': 'İncirli',
        'location': 'İncirli Campus, Vocational School Building',
        'building': 'İncirli Building',
        'floor': null,
        'roomCode': null,
        'type': 'Academic Unit',
        'abbr': 'MYO',
        'navigationHint': 'İncirli Campus, Vocational School building.',
        'verificationStatus': 'building_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 1,
      },
      {
        'id': 930002,
        'name': '1A01 Amphitheater / Classroom',
        'campus': 'İncirli',
        'location': 'İncirli Campus, İncirli Building, Room 1A01',
        'building': 'İncirli Building',
        'floor': null,
        'roomCode': '1A01',
        'possibleCorridor': 'A',
        'type': 'Classroom',
        'abbr': '1A01',
        'navigationHint': 'İncirli Building, room 1A01. Corridor A is inferred from the room code and should be verified on site.',
        'verificationStatus': 'room_verified_corridor_unverified',
        'needsVerification': true,
        'sortOrder': 2,
      },
      {
        'id': 930003,
        'name': '4A01 Amphitheater',
        'campus': 'İncirli',
        'location': 'İncirli Campus, İncirli Building, Room 4A01',
        'building': 'İncirli Building',
        'floor': null,
        'roomCode': '4A01',
        'possibleCorridor': 'A',
        'type': 'Classroom',
        'abbr': '4A01',
        'navigationHint': 'İncirli Building, room 4A01. Corridor A is inferred from the room code and should be verified on site.',
        'verificationStatus': 'room_verified_corridor_unverified',
        'needsVerification': true,
        'sortOrder': 3,
      },
      {
        'id': 930004,
        'name': 'Restaurant / Cafe',
        'campus': 'İncirli',
        'location': 'İncirli Campus, Ground Floor',
        'building': 'İncirli Building',
        'floor': 'Ground Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'RC',
        'navigationHint': 'İncirli Campus, ground floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 4,
      },
      {
        'id': 930005,
        'name': 'Health Unit',
        'campus': 'İncirli',
        'location': 'İncirli Campus',
        'building': 'İncirli Campus',
        'floor': null,
        'roomCode': null,
        'type': 'Health Unit',
        'abbr': 'REV',
        'navigationHint': 'Health unit is available at İncirli Campus. Floor information should be verified on site.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 5,
      },
      {
        'id': 930006,
        'name': 'Security Point',
        'campus': 'İncirli',
        'location': 'İncirli Campus, Main Entrance / Information Desk',
        'building': 'Main Entrance',
        'floor': null,
        'roomCode': null,
        'type': 'Security',
        'abbr': 'SEC',
        'navigationHint': 'Please go to the main entrance or information/security point.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 6,
      },
      {
        'id': 940001,
        'name': 'Faculty of Education',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Faculty of Education',
        'building': 'Basın Ekspres Campus',
        'floor': null,
        'roomCode': null,
        'type': 'Academic Unit',
        'abbr': 'EF',
        'navigationHint': 'Basın Ekspres / Küçükçekmece Campus, Faculty of Education.',
        'verificationStatus': 'building_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 1,
      },
      {
        'id': 940002,
        'name': 'Faculty of Economics and Administrative Sciences',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Faculty of Economics and Administrative Sciences',
        'building': 'Basın Ekspres Campus',
        'floor': null,
        'roomCode': null,
        'type': 'Academic Unit',
        'abbr': 'IIBF',
        'navigationHint': 'Basın Ekspres / Küçükçekmece Campus, Faculty of Economics and Administrative Sciences.',
        'verificationStatus': 'building_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 2,
      },
      {
        'id': 940003,
        'name': 'Basın Ekspres Library',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Block B, 2nd Floor',
        'building': 'Block B',
        'floor': '2nd Floor',
        'roomCode': null,
        'type': 'Library',
        'abbr': 'LIB',
        'navigationHint': 'Block B, 2nd floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 3,
      },
      {
        'id': 940004,
        'name': 'Conference Hall',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus',
        'building': 'Basın Ekspres Campus',
        'floor': null,
        'roomCode': null,
        'type': 'Hall',
        'abbr': 'KS',
        'navigationHint': 'Basın Ekspres / Küçükçekmece Campus. Floor information should be verified on site.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 4,
      },
      {
        'id': 940005,
        'name': 'Block A Classroom 203',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Block A, 2nd Floor, Classroom 203',
        'building': 'Block A',
        'floor': '2nd Floor',
        'roomCode': '203',
        'type': 'Classroom',
        'abbr': 'A203',
        'navigationHint': 'Block A, 2nd floor, classroom 203.',
        'verificationStatus': 'room_verified',
        'needsVerification': false,
        'sortOrder': 5,
      },
      {
        'id': 940006,
        'name': 'Academic Office 907',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Block B, 9th Floor, Room 907',
        'building': 'Block B',
        'floor': '9th Floor',
        'roomCode': '907',
        'type': 'Office',
        'abbr': 'B907',
        'navigationHint': 'Block B, 9th floor, room 907.',
        'verificationStatus': 'room_verified',
        'needsVerification': false,
        'sortOrder': 6,
      },
      {
        'id': 940007,
        'name': 'Basement Classroom L-02',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Basement Floor, L-02',
        'building': 'Basın Ekspres Campus',
        'floor': 'Basement Floor',
        'roomCode': 'L-02',
        'type': 'Classroom',
        'abbr': 'L02',
        'navigationHint': 'Basın Ekspres Campus, basement floor, L-02.',
        'verificationStatus': 'room_verified',
        'needsVerification': false,
        'sortOrder': 7,
      },
      {
        'id': 940008,
        'name': 'Best Coffee Shop',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Entrance Floor',
        'building': 'Basın Ekspres Campus',
        'floor': 'Entrance Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'BCS',
        'navigationHint': 'Basın Ekspres Campus, entrance floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 8,
      },
      {
        'id': 940009,
        'name': 'Makarna Pizza',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Entrance Floor',
        'building': 'Basın Ekspres Campus',
        'floor': 'Entrance Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'MP',
        'navigationHint': 'Basın Ekspres Campus, entrance floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 9,
      },
      {
        'id': 940010,
        'name': 'Lobby Restaurant',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Entrance Floor',
        'building': 'Basın Ekspres Campus',
        'floor': 'Entrance Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'LR',
        'navigationHint': 'Basın Ekspres Campus, entrance floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 10,
      },
      {
        'id': 940011,
        'name': 'Fast Food Cafe',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Entrance Floor',
        'building': 'Basın Ekspres Campus',
        'floor': 'Entrance Floor',
        'roomCode': null,
        'type': 'Food & Drink',
        'abbr': 'FFC',
        'navigationHint': 'Basın Ekspres Campus, entrance floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 11,
      },
      {
        'id': 940012,
        'name': 'Gözde Stationery Basın Ekspres',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, B1 Floor',
        'building': 'Basın Ekspres Campus',
        'floor': 'B1',
        'roomCode': null,
        'type': 'Service',
        'abbr': 'GK',
        'navigationHint': 'Basın Ekspres Campus, B1 floor.',
        'verificationStatus': 'floor_verified',
        'needsVerification': false,
        'sortOrder': 12,
      },
      {
        'id': 940013,
        'name': 'Security Point',
        'campus': 'Basın Ekspres',
        'location': 'Basın Ekspres / Küçükçekmece Campus, Main Entrance / Information Desk',
        'building': 'Main Entrance',
        'floor': null,
        'roomCode': null,
        'type': 'Security',
        'abbr': 'SEC',
        'navigationHint': 'Please go to the main entrance or information/security point.',
        'verificationStatus': 'campus_verified_floor_missing',
        'needsVerification': true,
        'sortOrder': 13,
      },
    ];

    final batch = _db.batch();

    for (final unit in demoUnits) {
      final id = unit['id'].toString();
      batch.set(
        _db.collection('buildings').doc(id),
        {
          ...unit,
          'isDemoSeed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    clearCollectionCache('buildings');
  }

  static String _demoAnnouncementDocId(String title) {
    return title
        .trim()
        .toLowerCase()
        .replaceAll('&', ' ')
        .replaceAll('/', ' ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String _demoAnnouncementDisplayDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  static String _demoAnnouncementDisplayTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static Future<void> resetDemoAnnouncementsForPresentation() async {
    final demoAnnouncements = <Map<String, dynamic>>[
      {
        'title': 'Midterm Exam Schedule Announced',
        'content': 'The midterm exam schedule has been published on the student information system. Students are expected to check their exam rooms before the exam week.',
        'category': 'academic',
        'publishAt': DateTime(2026, 5, 7, 8, 30),
      },
      {
        'title': 'Software Engineering Project Demo Reminder',
        'content': 'Project demo sessions will be held this week. Teams should prepare their working application, test results, and short presentation notes before the demo.',
        'category': 'academic',
        'publishAt': DateTime(2026, 5, 6, 16, 30),
      },
      {
        'title': 'Scholarship Applications Started',
        'content': 'Scholarship applications for the upcoming academic period are now open. Students can submit their documents through the student affairs office.',
        'category': 'scholarship',
        'publishAt': DateTime(2026, 5, 6, 9, 15),
      },
      {
        'title': 'Library Working Hours',
        'content': 'The library will remain open until 22:00 during the midterm and final exam preparation period.',
        'category': 'admin',
        'publishAt': DateTime(2026, 5, 5, 10, 0),
      },
      {
        'title': 'Summer School Registration',
        'content': 'Summer school pre-registration will be available between May 10 and May 24. Course availability will be announced by departments.',
        'category': 'academic',
        'publishAt': DateTime(2026, 5, 20, 14, 0),
      },
      {
        'title': 'Internship Application Deadline Reminder',
        'content': 'Students planning to complete their internship this summer must submit the required documents before the announced deadline.',
        'category': 'academic',
        'publishAt': DateTime(2026, 5, 18, 16, 0),
      },
      {
        'title': 'Student Card Renewal',
        'content': 'Students whose ID cards are damaged or expired can apply for card renewal through Student Affairs.',
        'category': 'admin',
        'publishAt': DateTime(2026, 5, 2, 11, 0),
      },
      {
        'title': 'Final Exam Calendar Draft Published',
        'content': 'The draft final exam calendar has been published for student review. Possible conflicts should be reported to the department secretary.',
        'category': 'academic',
        'publishAt': DateTime(2026, 5, 1, 13, 45),
      },
      {
        'title': 'Campus Shuttle Schedule Updated',
        'content': 'Campus shuttle departure times have been updated for the exam period. Students should check the latest schedule before travel.',
        'category': 'admin',
        'publishAt': DateTime(2026, 5, 28, 8, 45),
      },
      {
        'title': 'Career Days Registration Open',
        'content': 'Career Days registration is now open. Students can attend company talks, workshops, and recruitment sessions on campus.',
        'category': 'general',
        'publishAt': DateTime(2026, 4, 29, 12, 0),
      },
      {
        'title': 'Spring Festival 2026',
        'content': 'The Spring Festival will be held on campus on April 25–26. We look forward to seeing all our students at the events.',
        'category': 'general',
        'publishAt': DateTime(2026, 4, 28, 0, 0),
      },
      {
        'title': 'Cafeteria Menu Update',
        'content': 'The cafeteria menu and campus price list have been updated for the current week.',
        'category': 'admin',
        'publishAt': DateTime(2026, 4, 26, 10, 30),
      },
      {
        'title': 'Erasmus Information Meeting',
        'content': 'An Erasmus information meeting will be organized for students interested in exchange opportunities. Details will be shared by the international office.',
        'category': 'academic',
        'publishAt': DateTime(2026, 4, 24, 15, 0),
      },
    ];

    final batch = _db.batch();

    final existingAnnouncements = await _db.collection('announcements').get();
    for (final doc in existingAnnouncements.docs) {
      batch.delete(doc.reference);
    }

    for (final item in demoAnnouncements) {
      final title = item['title'].toString();
      final content = item['content'].toString();
      final category = item['category'].toString();
      final publishAt = item['publishAt'] as DateTime;
      final docId = _demoAnnouncementDocId(title);

      batch.set(
        _db.collection('announcements').doc(docId),
        {
          'id': docId,
          'title': title,
          'content': content,
          'category': category,
          'date': _demoAnnouncementDisplayDate(publishAt),
          'publishDate': _demoAnnouncementDisplayDate(publishAt),
          'publishTime': _demoAnnouncementDisplayTime(publishAt),
          'publishAt': Timestamp.fromDate(publishAt),
          'isNew': false,
          'createdAt': Timestamp.fromDate(publishAt),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: false),
      );
    }

    await batch.commit();

    clearCollectionCache('announcements');
  }


  static String _demoEventDocId(String title) {
    return title
        .trim()
        .toLowerCase()
        .replaceAll('&', ' ')
        .replaceAll('/', ' ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String _demoEventDisplayDate(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  static String _demoEventDisplayTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static Future<void> resetDemoEventsForPresentation() async {
    final demoEvents = <Map<String, dynamic>>[
      {
        'id': 2026051001,
        'title': 'Software Engineering Final Demo Day',
        'description': 'Student teams will present their final software engineering project demos, including working applications, test results, and improvement plans.',
        'category': 'academic',
        'location': 'Ataköy Campus / Conference Hall',
        'startAt': DateTime(2026, 5, 10, 10, 0),
      },
      {
        'id': 2026051101,
        'title': 'Career Days: Technology Companies Session',
        'description': 'Technology companies will meet students to introduce internship, part-time, and new graduate opportunities.',
        'category': 'social',
        'location': 'Ataköy Campus / Akıngüç Auditorium',
        'startAt': DateTime(2026, 5, 11, 13, 30),
      },
      {
        'id': 2026051201,
        'title': 'Mobile Programming Firebase Workshop',
        'description': 'A practical workshop about connecting Flutter applications to Firebase, reading Firestore data, and managing real-time updates.',
        'category': 'academic',
        'location': 'Engineering Faculty / Computer Lab',
        'startAt': DateTime(2026, 5, 12, 15, 0),
      },
      {
        'id': 2026051301,
        'title': 'Spring Music Night',
        'description': 'A campus music event organized by student clubs with live performances and social activities.',
        'category': 'cultural',
        'location': 'Ataköy Campus / Garden Area',
        'startAt': DateTime(2026, 5, 13, 18, 0),
      },
      {
        'id': 2026051401,
        'title': 'Basketball Tournament Finals',
        'description': 'The final matches of the student basketball tournament will be held with award ceremony after the last game.',
        'category': 'sports',
        'location': 'Ataköy Campus / Sports Hall',
        'startAt': DateTime(2026, 5, 14, 16, 0),
      },
      {
        'id': 2026051501,
        'title': 'Erasmus Information Seminar',
        'description': 'The international office will explain Erasmus application requirements, deadlines, documents, and partner universities.',
        'category': 'academic',
        'location': 'Ataköy Campus / Seminar Room 2',
        'startAt': DateTime(2026, 5, 15, 11, 0),
      },
      {
        'id': 2026051601,
        'title': 'AI and Data Science Student Talks',
        'description': 'Students and instructors will share short talks about artificial intelligence, data science, and project experiences.',
        'category': 'academic',
        'location': 'Engineering Faculty / Room C302',
        'startAt': DateTime(2026, 5, 16, 14, 0),
      },
      {
        'id': 2026051701,
        'title': 'Campus Photography Walk',
        'description': 'A cultural campus walk for students interested in photography, architecture, and visual storytelling.',
        'category': 'cultural',
        'location': 'Ataköy Campus / Main Entrance',
        'startAt': DateTime(2026, 5, 17, 12, 30),
      },
      {
        'id': 2026051801,
        'title': 'Volleyball Friendly Match',
        'description': 'A friendly volleyball match between departments will be organized for students and staff.',
        'category': 'sports',
        'location': 'Ataköy Campus / Sports Area',
        'startAt': DateTime(2026, 5, 18, 17, 0),
      },
      {
        'id': 2026051901,
        'title': 'Student Club Introduction Fair',
        'description': 'Student clubs will introduce their activities, membership opportunities, and upcoming events.',
        'category': 'social',
        'location': 'Ataköy Campus / Main Hall',
        'startAt': DateTime(2026, 5, 19, 10, 30),
      },
      {
        'id': 2026052001,
        'title': 'Exam Stress and Time Management Seminar',
        'description': 'A guidance seminar about managing exam stress, planning study sessions, and improving productivity during exam weeks.',
        'category': 'academic',
        'location': 'Ataköy Campus / Psychological Counseling Unit',
        'startAt': DateTime(2026, 5, 20, 13, 0),
      },
      {
        'id': 2026052101,
        'title': 'End of Semester Social Gathering',
        'description': 'A social gathering for students before the final exam period with club stands, music, and refreshments.',
        'category': 'social',
        'location': 'Ataköy Campus / Garden Area',
        'startAt': DateTime(2026, 5, 21, 17, 30),
      },
    ];

    final batch = _db.batch();

    final existingEvents = await _db.collection('events').get();
    for (final doc in existingEvents.docs) {
      batch.delete(doc.reference);
    }

    for (final item in demoEvents) {
      final id = item['id'] as int;
      final title = item['title'].toString();
      final description = item['description'].toString();
      final category = item['category'].toString();
      final location = item['location'].toString();
      final startAt = item['startAt'] as DateTime;
      final docId = id.toString();

      batch.set(
        _db.collection('events').doc(docId),
        {
          'id': id,
          'title': title,
          'description': description,
          'category': category,
          'date': _demoEventDisplayDate(startAt),
          'time': _demoEventDisplayTime(startAt),
          'location': location,
          'startAt': Timestamp.fromDate(startAt),
          'createdAt': Timestamp.fromDate(startAt),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: false),
      );
    }

    await batch.commit();

    clearCollectionCache('events');
  }

}