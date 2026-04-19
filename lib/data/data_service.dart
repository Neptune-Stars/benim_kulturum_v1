import 'dart:convert';
import 'package:flutter/services.dart';

class DataService {
  // JSON dosyasını okuyup Map (sözlük) yapısına çeviren asenkron fonksiyon
  static Future<Map<String, dynamic>> loadDatabase() async {
    try {
      // Dosyayı string olarak oku
      final String response = await rootBundle.loadString('assets/data.json');

      // Stringi JSON formatına (Map yapısına) dönüştür
      final data = await json.decode(response);
      return data;
    } catch (e) {
      print("Veritabanı yüklenirken hata oluştu: $e");
      return {};
    }
  }
}