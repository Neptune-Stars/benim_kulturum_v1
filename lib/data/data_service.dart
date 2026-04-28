import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String defaultCampus = "Ataköy Yerleşkesi";
  static const List<String> cafeteriaMealTypes = [
    "Kahvaltı",
    "Yemek",
    "Fast Food",
  ];

  static Future<Map<String, dynamic>> loadDatabase() async {
    final studentSnap = await _db.collection('students').limit(1).get();
    if (studentSnap.docs.isEmpty) {
      print("Öğrenciler eksik, varsayılan veriler Firebase'e yükleniyor...");
      await _seedExtraData();
    }

    final campusSnap = await _db.collection('campuses').limit(1).get();
    if (campusSnap.docs.isEmpty) {
      print("Kampüs referans verileri eksik, Firebase'e yükleniyor...");
      await _seedCampusReferenceData();
    }

    await ensureCafeteriaData();
    await ensureWeeklyCafeteriaMenus();

    final buildings = await _fetchList('buildings');
    final classrooms = await _fetchList('classrooms');
    final instructors = await _fetchList('instructors');
    final events = await _fetchList('events');
    final announcements = await _fetchList('announcements');
    final prices = await _fetchList('prices');
    final issues = await _fetchList('issues');
    final students = await _fetchList('students');

    // Admin dropdown data comes from Firebase.
    final campuses = await _fetchList('campuses');
    final classroomLocations = await _fetchList('classroomLocations');

    final cafeteriaDoc = await _db.collection('settings').doc('cafeteria').get();

    return {
      'buildings': buildings,
      'classrooms': classrooms,
      'instructors': instructors,
      'events': events,
      'announcements': announcements,
      'prices': prices,
      'issues': issues,
      'students': students,
      'campuses': campuses,
      'classroomLocations': classroomLocations,
      'cafeteria': cafeteriaDoc.exists ? cafeteriaDoc.data() : {},
    };
  }

  static Future<List<Map<String, dynamic>>> _fetchList(String collectionName) async {
    final querySnapshot = await _db.collection(collectionName).get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['firestoreDocId'] = doc.id;
      return data;
    }).toList();
  }

  static Map<String, dynamic> _defaultCafeteriaData() {
    return {
      "mealTypes": cafeteriaMealTypes,
      "defaultCampus": defaultCampus,
      "weekdayDefaultMealType": "Yemek",
      "weekendDefaultMealType": "Fast Food",
      "menus": {
        "Kahvaltı": {
          "menuName": "Kahvaltı Menüsü",
          "time": "08:00-10:00",
          "price": "₺25",
          "items": [
            "Peynir",
            "Zeytin",
            "Domates",
            "Salatalık",
            "Reçel",
            "Tereyağı",
            "Haşlanmış yumurta",
            "Çay"
          ],
          "isChips": true,
        },
        "Yemek": {
          "menuName": "Bugünün Yemeği",
          "time": "13:00-18:00",
          "price": "₺35",
          "items": [
            "Mercimek Çorbası",
            "Tavuk Şinitzel",
            "Pilav",
            "Mevsim Salata",
            "Ayran"
          ],
          "isChips": false,
        },
        "Fast Food": {
          "menuName": "Fast Food Menüsü",
          "time": "10:00-18:00",
          "price": "Ürün bazlı",
          "items": [
            {"name": "Izgara Köfte Menü", "price": "₺75"},
            {"name": "Tavuk Şinitzel Menü", "price": "₺70"},
            {"name": "Penne Makarna", "price": "₺55"},
            {"name": "Patates Kızartması", "price": "₺35"},
            {"name": "Kaşarlı Tost", "price": "₺40"}
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
      print("Yemekhane verisi ilk kez oluşturuldu.");
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

    fixedMenus["Kahvaltı"] = _mergeMenu(
      defaultMenus["Kahvaltı"],
      currentMenus["Kahvaltı"],
      fallbackMenuName: "Kahvaltı Menüsü",
    );

    final existingFoodMenu = currentMenus["Yemek"] ?? currentMenus["Öğle"];

    fixedMenus["Yemek"] = _mergeMenu(
      defaultMenus["Yemek"],
      existingFoodMenu,
      fallbackMenuName: "Bugünün Yemeği",
      forcedTime: "13:00-18:00",
    );

    fixedMenus["Fast Food"] = _mergeMenu(
      defaultMenus["Fast Food"],
      currentMenus["Fast Food"],
      fallbackMenuName: "Fast Food Menüsü",
      itemsHavePrices: true,
    );

    final fixedMealTypes = <String>[
      "Kahvaltı",
      "Yemek",
      "Fast Food",
    ];

    // Admin ileride özel kategori eklerse korunur.
    for (final mealType in currentMealTypes) {
      if (mealType == "Öğle" ||
          mealType == "Akşam" ||
          mealType == "Günün Menüsü") {
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
      "weekdayDefaultMealType": currentData['weekdayDefaultMealType'] ?? "Yemek",
      "weekendDefaultMealType": currentData['weekendDefaultMealType'] ?? "Fast Food",
      "menus": fixedMenus,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print("Yemekhane verisi kontrol edildi ve eksikler onarıldı.");
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
      merged["price"] = "Ürün bazlı";
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
      (defaultMenus[normalizedMealType] ?? defaultMenus['Yemek']) as Map,
    );
  }

  static String normalizeMealType(String mealType) {
    final trimmed = mealType.trim();
    if (trimmed == "Öğle" || trimmed == "Akşam" || trimmed == "Günün Menüsü") {
      return "Yemek";
    }
    return trimmed;
  }

  static DateTime startOfWeek(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    return cleanDate.subtract(Duration(days: cleanDate.weekday - 1));
  }

  static bool isWeekend(DateTime date) => date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  static String defaultMealTypeForDate(DateTime date) {
    return isWeekend(date) ? "Fast Food" : "Yemek";
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
        return "Pazartesi";
      case DateTime.tuesday:
        return "Salı";
      case DateTime.wednesday:
        return "Çarşamba";
      case DateTime.thursday:
        return "Perşembe";
      case DateTime.friday:
        return "Cuma";
      case DateTime.saturday:
        return "Cumartesi";
      case DateTime.sunday:
        return "Pazar";
      default:
        return "Bilinmiyor";
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

  static String cafeteriaMenuDocId({
    required DateTime date,
    String campus = defaultCampus,
    required String mealType,
  }) {
    return "${formatDateKey(date)}_${_slug(campus)}_${_slug(normalizeMealType(mealType))}";
  }

  static String cafeteriaDayStatusDocId({
    required DateTime date,
    String campus = defaultCampus,
  }) {
    return "${formatDateKey(date)}_${_slug(campus)}";
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
      "campus": campus,
      "isWeekend": weekend,
      "isDayActive": isDayActive ?? true,
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

    if (!doc.exists || doc.data() == null) {
      await docRef.set(
        buildCafeteriaDayStatusDocument(
          date: date,
          campus: campus,
          isDayActive: true,
        )..addAll({"createdAt": FieldValue.serverTimestamp()}),
      );
      return;
    }

    final current = Map<String, dynamic>.from(doc.data()!);
    await docRef.set({
      ...buildCafeteriaDayStatusDocument(
        date: date,
        campus: campus,
        isDayActive: current['isDayActive'] != false,
      ),
      "createdAt": current['createdAt'],
    }, SetOptions(merge: true));
  }

  static Future<void> setCafeteriaDayActiveStatus(
      DateTime date,
      bool isActive, {
        String campus = defaultCampus,
      }) async {
    final dayStatusId = cafeteriaDayStatusDocId(date: date, campus: campus);

    await _db.collection('cafeteriaDayStatuses').doc(dayStatusId).set(
      buildCafeteriaDayStatusDocument(
        date: date,
        campus: campus,
        isDayActive: isActive,
      ),
      SetOptions(merge: true),
    );

    for (final mealType in cafeteriaMealTypes) {
      final menuDocId = cafeteriaMenuDocId(
        date: date,
        campus: campus,
        mealType: mealType,
      );

      await _db.collection('cafeteriaMenus').doc(menuDocId).set({
        "isDayActive": isActive,
        "dayStatusId": dayStatusId,
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
    final docId = cafeteriaMenuDocId(
      date: date,
      campus: campus,
      mealType: normalizedMealType,
    );

    await _db.collection('cafeteriaMenus').doc(docId).set({
      "isActive": isActive,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      forcedTime: normalizedMealType == "Yemek" ? "13:00-18:00" : null,
      itemsHavePrices: normalizedMealType == "Fast Food",
    );

    final dayStatusId = cafeteriaDayStatusDocId(date: date, campus: campus);
    final visibleByDefault = isWeekend(date)
        ? normalizedMealType == "Fast Food"
        : true;

    final data = <String, dynamic>{
      "id": cafeteriaMenuDocId(date: date, campus: campus, mealType: normalizedMealType),
      "date": formatDateKey(date),
      "displayDate": formatDisplayDate(date),
      "weekStart": formatDateKey(startOfWeek(date)),
      "weekday": weekdayName(date.weekday),
      "weekdayIndex": date.weekday,
      "campus": campus,
      "mealType": normalizedMealType,
      "menuName": completedMenu['menuName'],
      "time": completedMenu['time'],
      "price": completedMenu['price'],
      "items": completedMenu['items'],
      "isChips": completedMenu['isChips'] ?? false,
      "isWeekend": isWeekend(date),
      "dayStatusId": dayStatusId,
      "isDayActive": isDayActive ?? menu['isDayActive'] ?? true,
      "isActive": menu['isActive'] ?? visibleByDefault,
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

    for (final mealType in cafeteriaMealTypes) {
      final docId = cafeteriaMenuDocId(date: date, campus: campus, mealType: mealType);
      final docRef = _db.collection('cafeteriaMenus').doc(docId);
      final doc = await docRef.get();

      if (!doc.exists || doc.data() == null) {
        final defaultMenu = defaultMenuForMealType(mealType);
        await docRef.set(
          buildCafeteriaMenuDocument(
            date: date,
            campus: campus,
            mealType: mealType,
            menu: defaultMenu,
            includeCreatedAt: true,
            isDayActive: isDayActive,
          ),
        );
      } else {
        final currentMenu = Map<String, dynamic>.from(doc.data()!);
        await docRef.set(
          buildCafeteriaMenuDocument(
            date: date,
            campus: campus,
            mealType: mealType,
            menu: currentMenu,
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

  static Future<Map<String, Map<String, dynamic>>> fetchDailyCafeteriaMenus(
      DateTime date, {
        String campus = defaultCampus,
      }) async {
    await ensureDailyCafeteriaMenus(date, campus: campus);

    final result = <String, Map<String, dynamic>>{};

    for (final mealType in cafeteriaMealTypes) {
      final docId = cafeteriaMenuDocId(date: date, campus: campus, mealType: mealType);
      final doc = await _db.collection('cafeteriaMenus').doc(docId).get();
      result[mealType] = doc.data() == null
          ? buildCafeteriaMenuDocument(
        date: date,
        campus: campus,
        mealType: mealType,
        menu: defaultMenuForMealType(mealType),
      )
          : Map<String, dynamic>.from(doc.data()!);
    }

    return result;
  }

  static Future<List<Map<String, dynamic>>> fetchWeeklyCafeteriaMenus({
    DateTime? weekStart,
    String campus = defaultCampus,
  }) async {
    final start = startOfWeek(weekStart ?? DateTime.now());
    await ensureWeeklyCafeteriaMenus(weekStart: start, campus: campus);

    final days = <Map<String, dynamic>>[];

    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final menus = await fetchDailyCafeteriaMenus(date, campus: campus);
      final dayStatus = await fetchCafeteriaDayStatus(date, campus: campus);

      days.add({
        "date": date,
        "dateKey": formatDateKey(date),
        "displayDate": formatDisplayDate(date),
        "weekday": weekdayName(date.weekday),
        "weekdayIndex": date.weekday,
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
  }) async* {
    final today = DateTime.now();
    final dateKey = formatDateKey(today);
    final dayStatusId = cafeteriaDayStatusDocId(date: today, campus: campus);

    await ensureDailyCafeteriaMenus(today, campus: campus);

    yield* _db
        .collection('cafeteriaDayStatuses')
        .doc(dayStatusId)
        .snapshots()
        .asyncExpand((daySnapshot) {
      final dayData = daySnapshot.data() == null
          ? buildCafeteriaDayStatusDocument(date: today, campus: campus)
          : Map<String, dynamic>.from(daySnapshot.data()!);

      final isDayActive = dayData['isDayActive'] != false;

      if (!isDayActive) {
        return Stream<Map<String, dynamic>>.value({
          "menuName": "Bugün Yemekhane Hizmeti Yok",
          "mealType": "Kapalı",
          "time": "-",
          "price": "-",
          "items": <dynamic>[],
          "isDayActive": false,
          "isActive": false,
          "dashboardMode": "day_closed",
          "dashboardMessage": "Bugün için yemekhane veya Fast Food hizmeti aktif değil.",
        });
      }

      return _db
          .collection('cafeteriaMenus')
          .where('date', isEqualTo: dateKey)
          .where('campus', isEqualTo: campus)
          .snapshots()
          .map((query) {
        final menusByType = <String, Map<String, dynamic>>{};

        for (final doc in query.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          final mealType = data['mealType']?.toString() ?? '';
          final visible = data['isDayActive'] != false && data['isActive'] != false;

          if (mealType.isNotEmpty && visible) {
            menusByType[mealType] = data;
          }
        }

        final priority = isWeekend(today)
            ? <String>["Fast Food"]
            : <String>["Yemek", "Fast Food", "Kahvaltı"];

        for (final mealType in priority) {
          if (menusByType.containsKey(mealType)) {
            final data = menusByType[mealType]!;
            data['dashboardMode'] = isWeekend(today) ? 'weekend_fastfood' : 'weekday_meal';
            data['dashboardMessage'] = isWeekend(today)
                ? 'Bugün hafta sonu. Aktif Fast Food seçenekleri gösteriliyor.'
                : 'Bugün hafta içi. Aktif kampüs menüsü gösteriliyor.';
            return data;
          }
        }

        return {
          "menuName": "Bugün Menü Bulunmuyor",
          "mealType": "Kapalı",
          "time": "-",
          "price": "-",
          "items": <dynamic>[],
          "isDayActive": true,
          "isActive": false,
          "dashboardMode": "no_active_menu",
          "dashboardMessage": "Bugün için aktif menü bulunmuyor.",
        };
      });
    });
  }

  static Future<void> _seedCafeteriaData() async {
    await _db.collection('settings').doc('cafeteria').set(
      _defaultCafeteriaData(),
    );
  }

  static Future<void> _seedExtraData() async {
    final List<Map<String, dynamic>> starterPrices = [
      {"id": 1, "name": "Çay", "price": "₺3", "category": "Çay/Kahve"},
      {"id": 2, "name": "Türk Kahvesi", "price": "₺12", "category": "Çay/Kahve"},
      {"id": 3, "name": "Ayran", "price": "₺5", "category": "İçecekler"},
      {"id": 4, "name": "Tost", "price": "₺15", "category": "Atıştırmalıklar"},
      {"id": 5, "name": "Bugünün Yemeği", "price": "₺35", "category": "Yemek"},
    ];

    for (final item in starterPrices) {
      await _db.collection('prices').doc(item['id'].toString()).set(item);
    }

    final List<Map<String, dynamic>> starterIssues = [
      {
        "id": 1,
        "category": "Altyapı Sorunu",
        "priority": "Yüksek",
        "subject": "Sınıfta projeksiyon çalışmıyor",
        "location": "MF-101",
        "description": "Bilgisayarı bağladığımızda görüntü gelmiyor.",
        "date": "Bugün 10:30",
        "status": "Açık",
        "createdAt": FieldValue.serverTimestamp(),
        "resolvedAt": null,
      },
      {
        "id": 2,
        "category": "Temizlik",
        "priority": "Orta",
        "subject": "Lavabolarda sabun bitti",
        "location": "İİBF 2. Kat",
        "description": "Erkekler tuvaletindeki sıvı sabunluklar tamamen boşalmış.",
        "date": "Dün 14:15",
        "status": "Açık",
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
        "name": "Örnek Öğrenci",
        "no": "20210001234",
        "email": "ogrenci@uni.edu.tr",
        "password": "123456",
        "grade": "3. Sınıf",
      },
      {
        "id": 2,
        "name": "Ayşe Demir",
        "no": "20220005678",
        "email": "ayse@uni.edu.tr",
        "password": "password123",
        "grade": "2. Sınıf",
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
        "displayName": "Ataköy Yerleşkesi",
        "officialGroup": "Bakırköy Yerleşkesi",
        "sortOrder": 1,
      },
      {
        "id": "incirli",
        "name": "İncirli",
        "displayName": "İncirli Yerleşkesi",
        "officialGroup": "Bakırköy Yerleşkesi",
        "sortOrder": 2,
      },
      {
        "id": "sirin_evler",
        "name": "Şirinevler",
        "displayName": "Şirinevler / Bahçelievler Yerleşkesi",
        "officialGroup": "Bahçelievler Yerleşkesi",
        "sortOrder": 3,
      },
      {
        "id": "basin_ekspres",
        "name": "Basın Ekspres",
        "displayName": "Basın Ekspres / Küçükçekmece Yerleşkesi",
        "officialGroup": "Küçükçekmece Yerleşkesi",
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
        "campusName": "Ataköy Yerleşkesi",
        "name": "Ataköy Binası",
        "type": "building",
        "sortOrder": 1,
      },
      {
        "id": "atakoy_muhendislik",
        "campusId": "atakoy",
        "campusName": "Ataköy Yerleşkesi",
        "name": "Mühendislik Fakültesi",
        "type": "faculty",
        "sortOrder": 2,
      },
      {
        "id": "atakoy_mimarlik",
        "campusId": "atakoy",
        "campusName": "Ataköy Yerleşkesi",
        "name": "Mimarlık Fakültesi",
        "type": "faculty",
        "sortOrder": 3,
      },
      {
        "id": "atakoy_sanat_tasarim",
        "campusId": "atakoy",
        "campusName": "Ataköy Yerleşkesi",
        "name": "Sanat ve Tasarım Fakültesi",
        "type": "faculty",
        "sortOrder": 4,
      },
      {
        "id": "atakoy_fen_edebiyat",
        "campusId": "atakoy",
        "campusName": "Ataköy Yerleşkesi",
        "name": "Fen-Edebiyat Fakültesi",
        "type": "faculty",
        "sortOrder": 5,
      },
      {
        "id": "incirli_bina",
        "campusId": "incirli",
        "campusName": "İncirli Yerleşkesi",
        "name": "İncirli Binası",
        "type": "building",
        "sortOrder": 1,
      },
      {
        "id": "incirli_myo",
        "campusId": "incirli",
        "campusName": "İncirli Yerleşkesi",
        "name": "Meslek Yüksekokulu",
        "type": "school",
        "sortOrder": 2,
      },
      {
        "id": "sirin_evler_bina",
        "campusId": "sirin_evler",
        "campusName": "Şirinevler / Bahçelievler Yerleşkesi",
        "name": "Şirinevler Binası",
        "type": "building",
        "sortOrder": 1,
      },
      {
        "id": "sirin_evler_hukuk",
        "campusId": "sirin_evler",
        "campusName": "Şirinevler / Bahçelievler Yerleşkesi",
        "name": "Hukuk Fakültesi",
        "type": "faculty",
        "sortOrder": 2,
      },
      {
        "id": "sirin_evler_saglik",
        "campusId": "sirin_evler",
        "campusName": "Şirinevler / Bahçelievler Yerleşkesi",
        "name": "Sağlık Bilimleri Fakültesi",
        "type": "faculty",
        "sortOrder": 3,
      },
      {
        "id": "sirin_evler_yabanci_diller",
        "campusId": "sirin_evler",
        "campusName": "Şirinevler / Bahçelievler Yerleşkesi",
        "name": "Yabancı Diller",
        "type": "unit",
        "sortOrder": 4,
      },
      {
        "id": "basin_ekspres_bina",
        "campusId": "basin_ekspres",
        "campusName": "Basın Ekspres / Küçükçekmece Yerleşkesi",
        "name": "Basın Ekspres Binası",
        "type": "building",
        "sortOrder": 1,
      },
      {
        "id": "basin_ekspres_egitim",
        "campusId": "basin_ekspres",
        "campusName": "Basın Ekspres / Küçükçekmece Yerleşkesi",
        "name": "Eğitim Fakültesi",
        "type": "faculty",
        "sortOrder": 2,
      },
      {
        "id": "basin_ekspres_iibf",
        "campusId": "basin_ekspres",
        "campusName": "Basın Ekspres / Küçükçekmece Yerleşkesi",
        "name": "İktisadi ve İdari Bilimler Fakültesi",
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
}
