import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  static Future<void> _seedExtraData() async {
    final List<Map<String, dynamic>> starterPrices = [
      {"id": 1, "name": "Çay", "price": "₺3", "category": "Çay/Kahve"},
      {"id": 2, "name": "Türk Kahvesi", "price": "₺12", "category": "Çay/Kahve"},
      {"id": 3, "name": "Ayran", "price": "₺5", "category": "İçecekler"},
      {"id": 4, "name": "Tost", "price": "₺15", "category": "Atıştırmalıklar"},
      {"id": 5, "name": "Öğle Menüsü", "price": "₺35", "category": "Yemek"},
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