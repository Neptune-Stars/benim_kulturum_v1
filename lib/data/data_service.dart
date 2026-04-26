import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> loadDatabase() async {
    // 1. KONTROL: Binalar VEYA Derslikler eksik mi?
    var buildingSnap = await _db.collection('buildings').limit(1).get();
    var classroomSnap = await _db.collection('classrooms').limit(1).get();

    if (buildingSnap.docs.isEmpty || classroomSnap.docs.isEmpty) {
      print("Kampüs verileri eksik, JSON'dan Firebase'e yükleniyor...");
      await _seedFirestore();
    }

    // 2. KONTROL: Fiyatlar VEYA Yemekhane ayarları eksik mi? (Bunu düzelttik!)
    var priceSnap = await _db.collection('prices').limit(1).get();
    var cafeteriaDocCheck = await _db.collection('settings').doc('cafeteria').get();

    if (priceSnap.docs.isEmpty || !cafeteriaDocCheck.exists) {
      print("Yemekhane veya Fiyat verileri eksik, Firebase'e yükleniyor...");
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

  static Future<void> _seedFirestore() async {
    final jsonString = await rootBundle.loadString('assets/data.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    for (var item in jsonData['buildings'] ?? []) { await _db.collection('buildings').doc(item['id'].toString()).set(item); }
    for (var item in jsonData['classrooms'] ?? []) { await _db.collection('classrooms').doc(item['id'].toString()).set(item); }
    for (var item in jsonData['instructors'] ?? []) { await _db.collection('instructors').doc(item['id'].toString()).set(item); }
    for (var item in jsonData['events'] ?? []) { await _db.collection('events').doc(item['id'].toString()).set(item); }
    for (var item in jsonData['announcements'] ?? []) { await _db.collection('announcements').doc(item['id'].toString()).set(item); }
  }

  static Future<void> _seedExtraData() async {
    final List<Map<String, dynamic>> starterPrices = [
      {"id": 1, "name": "Çay", "price": "₺12", "category": "Sıcak İçecekler"},
      {"id": 2, "name": "Filtre Kahve", "price": "₺40", "category": "Sıcak İçecekler"},
      {"id": 3, "name": "Americano", "price": "₺45", "category": "Sıcak İçecekler"},
      {"id": 4, "name": "Latte", "price": "₺50", "category": "Sıcak İçecekler"},
      {"id": 5, "name": "Su (0.5L)", "price": "₺8", "category": "Soğuk İçecekler"},
      {"id": 6, "name": "Maden Suyu", "price": "₺15", "category": "Soğuk İçecekler"},
      {"id": 7, "name": "Kaşarlı Tost", "price": "₺55", "category": "Yiyecekler"},
      {"id": 8, "name": "Karışık Tost", "price": "₺70", "category": "Yiyecekler"},
      {"id": 9, "name": "Soğuk Sandviç (Hindi Füme)", "price": "₺75", "category": "Yiyecekler"},
      {"id": 10, "name": "Dilim Kek", "price": "₺40", "category": "Yiyecekler"},
      {"id": 11, "name": "Eti Browni Gold", "price": "₺15", "category": "Paketli Ürünler"},
      {"id": 12, "name": "Ülker Hoşbeş", "price": "₺20", "category": "Paketli Ürünler"},
      {"id": 13, "name": "Eti Burçak", "price": "₺18", "category": "Paketli Ürünler"},
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

    // STANDART ÖĞÜNLER (Tek Fiyat)
    Map<String, dynamic> atabldot = {"isAlaCarte": false, "time": "11:30-14:30", "price": "₺45", "items": ["Mercimek Çorbası", "Orman Kebabı", "Pirinç Pilavı", "Cacık"]};
    Map<String, dynamic> btabldot = {"isAlaCarte": false, "time": "11:30-14:30", "price": "₺45", "items": ["Ezogelin Çorbası", "Fırın Baget", "Soslu Makarna", "Meyve"]};
    Map<String, dynamic> kahvalti = {"isAlaCarte": false, "time": "08:00-10:00", "price": "₺30", "items": ["Haşlanmış Yumurta", "Beyaz Peynir", "Zeytin", "Reçel", "Çay"]};

    // FAST FOOD (Her ürünün kendi fiyatı var)
    Map<String, dynamic> fastfood = {
      "isAlaCarte": true,
      "time": "10:30-16:00",
      "items": [
        {"name": "Tavuk Döner Dürüm", "price": "₺90"},
        {"name": "Et Döner Dürüm", "price": "₺140"},
        {"name": "Hamburger Menü", "price": "₺120"},
        {"name": "Tavuk Şinitzel Menü", "price": "₺110"},
        {"name": "Patates Kızartması", "price": "₺40"}
      ]
    };

    final Map<String, dynamic> cafeteriaData = {
      "campuses": ["Ataköy", "Şirinevler", "İncirli", "Basın Ekspres"],
      "menus": {
        "Ataköy": {
          "Pazartesi": {"Öğle": atabldot, "Fast Food": fastfood},
          "Salı": {"Öğle": btabldot, "Fast Food": fastfood},
          "Çarşamba": {"Öğle": atabldot, "Fast Food": fastfood},
          "Perşembe": {"Öğle": btabldot, "Fast Food": fastfood},
          "Cuma": {"Öğle": atabldot, "Fast Food": fastfood},
          "Hafta Sonu": {"Fast Food": fastfood}
        },
        "Şirinevler": {
          "Pazartesi": {"Kahvaltı": kahvalti, "Öğle": atabldot, "Fast Food": fastfood},
          "Salı": {"Kahvaltı": kahvalti, "Öğle": btabldot, "Fast Food": fastfood},
          "Çarşamba": {"Kahvaltı": kahvalti, "Öğle": atabldot, "Fast Food": fastfood},
          "Perşembe": {"Kahvaltı": kahvalti, "Öğle": btabldot, "Fast Food": fastfood},
          "Cuma": {"Kahvaltı": kahvalti, "Öğle": atabldot, "Fast Food": fastfood},
          "Hafta Sonu": {"Fast Food": fastfood}
        },
        "İncirli": {
          "Pazartesi": {"Kahvaltı": kahvalti, "Öğle": atabldot, "Fast Food": fastfood},
          "Salı": {"Kahvaltı": kahvalti, "Öğle": btabldot, "Fast Food": fastfood},
          "Çarşamba": {"Kahvaltı": kahvalti, "Öğle": atabldot, "Fast Food": fastfood},
          "Perşembe": {"Kahvaltı": kahvalti, "Öğle": btabldot, "Fast Food": fastfood},
          "Cuma": {"Kahvaltı": kahvalti, "Öğle": atabldot, "Fast Food": fastfood},
          "Hafta Sonu": {"Fast Food": fastfood}
        },
        "Basın Ekspres": {
          "Pazartesi": {"Kahvaltı": kahvalti, "Öğle": atabldot, "Fast Food": fastfood},
          "Salı": {"Kahvaltı": kahvalti, "Öğle": btabldot, "Fast Food": fastfood},
          "Çarşamba": {"Kahvaltı": kahvalti, "Öğle": atabldot, "Fast Food": fastfood},
          "Perşembe": {"Kahvaltı": kahvalti, "Öğle": btabldot, "Fast Food": fastfood},
          "Cuma": {"Kahvaltı": kahvalti, "Öğle": atabldot, "Fast Food": fastfood},
          "Hafta Sonu": {"Fast Food": fastfood}
        }
      }
    };

    await _db.collection('settings').doc('cafeteria').set(cafeteriaData);
  }
}