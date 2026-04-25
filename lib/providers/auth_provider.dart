import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? role; // "student" or "admin"

  // YENİ: Giriş yapan kullanıcının tüm bilgilerini tutacak obje
  Map<String, dynamic>? userData;

  bool get isLoggedIn => role != null;
  bool get isAdmin => role == 'admin';

  // YENİ: Giriş yaparken artık kullanıcı verisini de alıyoruz
  void login(String r, {Map<String, dynamic>? data}) {
    role = r;
    userData = data;
    notifyListeners();
  }

  void logout() {
    role = null;
    userData = null; // Çıkış yapınca veriyi temizle
    notifyListeners();
  }
}