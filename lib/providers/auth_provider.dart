import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? role; // "student" or "admin"

  bool get isLoggedIn => role != null;
  bool get isAdmin => role == 'admin';

  void login(String r) {
    role = r;
    notifyListeners();
  }

  void logout() {
    role = null;
    notifyListeners();
  }
}