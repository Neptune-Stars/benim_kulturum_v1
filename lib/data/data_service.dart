import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> loadDatabase() async {
    // 1. KONTROL: Binalar var mı? (Eğer yoksa data.json'ı yükle)
    var buildingSnap = await _db.collection('buildings').limit(1).get();
    if (buildingSnap.docs.isEmpty) {
      print("Binalar eksik, JSON'dan Firebase'e yükleniyor...");
      await _seedFirestore();
    }

    // 2. KONTROL: Öğrenciler var mı? (Eğer yoksa ekstra verileri yükle)
    var studentSnap = await _db.collection('students').limit(1).get();
    if (studentSnap.docs.isEmpty) {
      print("Öğrenciler eksik, varsayılan veriler Firebase'e yükleniyor...");
      await _seedExtraData();
    }

    // 3. Her şeyi Firebase'den çekip uygulamaya gönderiyoruz
    final buildings = await _fetchList('buildings');
    final classrooms = await _fetchList('classrooms');
    final instructors = await _fetchList('instructors');
    final events = await _fetchList('events');
    final announcements = await _fetchList('announcements');

    final prices = await _fetchList('prices');
    final issues = await _fetchList('issues');
    final students = await _fetchList('students');

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
      'cafeteria': cafeteriaDoc.exists ? cafeteriaDoc.data() : {},
    };
  }

  static Future<List<Map<String, dynamic>>> _fetchList(String collectionName) async {
    final querySnapshot = await _db.collection(collectionName).get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  // Sadece JSON içindeki temel kampüs verilerini yükler
  static Future<void> _seedFirestore() async {
    final jsonString = await rootBundle.loadString('assets/data.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    for (var item in jsonData['buildings'] ?? []) { await _db.collection('buildings').doc(item['id'].toString()).set(item); }
    for (var item in jsonData['classrooms'] ?? []) { await _db.collection('classrooms').doc(item['id'].toString()).set(item); }
    for (var item in jsonData['instructors'] ?? []) { await _db.collection('instructors').doc(item['id'].toString()).set(item); }
    for (var item in jsonData['events'] ?? []) { await _db.collection('events').doc(item['id'].toString()).set(item); }
    for (var item in jsonData['announcements'] ?? []) { await _db.collection('announcements').doc(item['id'].toString()).set(item); }
    if (jsonData['cafeteria'] != null) { await _db.collection('settings').doc('cafeteria').set(jsonData['cafeteria']); }
  }

  // Öğrenci, Sorunlar ve Fiyatlar gibi UI içinde sonradan eklediğimiz verileri yükler
  static Future<void> _seedExtraData() async {
    final List<Map<String, dynamic>> starterPrices = [
      {"id": 1, "name": "Çay", "price": "₺3", "category": "Çay/Kahve"},
      {"id": 2, "name": "Türk Kahvesi", "price": "₺12", "category": "Çay/Kahve"},
      {"id": 3, "name": "Ayran", "price": "₺5", "category": "İçecekler"},
      {"id": 4, "name": "Tost", "price": "₺15", "category": "Atıştırmalıklar"},
      {"id": 5, "name": "Öğle Menüsü", "price": "₺35", "category": "Yemek"},
    ];
    for (var item in starterPrices) { await _db.collection('prices').doc(item['id'].toString()).set(item); }

    final List<Map<String, dynamic>> starterIssues = [
      { "id": 1, "category": "Altyapı Sorunu", "priority": "Yüksek", "subject": "Sınıfta projeksiyon çalışmıyor", "location": "MF-101", "description": "Bilgisayarı bağladığımızda görüntü gelmiyor.", "date": "Bugün 10:30" },
      { "id": 2, "category": "Temizlik", "priority": "Orta", "subject": "Lavabolarda sabun bitti", "location": "İİBF 2. Kat", "description": "Erkekler tuvaletindeki sıvı sabunluklar tamamen boşalmış.", "date": "Dün 14:15" }
    ];
    for (var item in starterIssues) { await _db.collection('issues').doc(item['id'].toString()).set(item); }

    final List<Map<String, dynamic>> starterStudents = [
      {"id": 1, "name": "Örnek Öğrenci", "no": "20210001234", "email": "ogrenci@uni.edu.tr", "password": "123456", "grade": "3. Sınıf"},
      {"id": 2, "name": "Ayşe Demir", "no": "20220005678", "email": "ayse@uni.edu.tr", "password": "password123", "grade": "2. Sınıf"},
    ];
    for (var item in starterStudents) { await _db.collection('students').doc(item['id'].toString()).set(item); }
  }
}