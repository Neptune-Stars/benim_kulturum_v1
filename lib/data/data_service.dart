import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DataService {
  // Ana veritabanı okuma fonksiyonumuz
  static Future<Map<String, dynamic>> loadDatabase() async {
    var box = Hive.box('campusDataBox');

    // 1. ADIM: Veritabanı boş mu diye kontrol et (Uygulama ilk kez mi açılıyor?)
    if (box.isEmpty) {
      print("Veritabanı boş! JSON'dan tohumlama (seeding) yapılıyor...");

      // JSON dosyasını oku
      final jsonString = await rootBundle.loadString('assets/data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // JSON'daki tüm verileri Hive veritabanına kaydet
      await box.put('buildings', jsonData['buildings']);
      await box.put('classrooms', jsonData['classrooms']);
      await box.put('instructors', jsonData['instructors']);
      await box.put('events', jsonData['events']);
      await box.put('announcements', jsonData['announcements']);
      await box.put('cafeteria', jsonData['cafeteria']);
      await box.put('campusPrices', jsonData['campusPrices']);

      print("Tohumlama başarılı! Veriler veritabanına yazıldı.");
    }

    // 2. ADIM: Artık veriyi JSON'dan değil, kalıcı Hive veritabanından çekip gönderiyoruz
    return {
      'buildings': box.get('buildings', defaultValue: []),
      'classrooms': box.get('classrooms', defaultValue: []),
      'instructors': box.get('instructors', defaultValue: []),
      'events': box.get('events', defaultValue: []),
      'announcements': box.get('announcements', defaultValue: []),
      'cafeteria': box.get('cafeteria', defaultValue: {}),
      'campusPrices': box.get('campusPrices', defaultValue: {}),
    };
  }

  // Adminler için Yemek Menüsü Güncelleme Fonksiyonu
  static Future<void> updateCafeteriaMenu(Map<String, dynamic> newMenuData) async {
    var box = Hive.box('campusDataBox');
    await box.put('cafeteria', newMenuData); // Veritabanındaki menüyü ezer/günceller
  }
}