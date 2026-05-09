import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? role; // "student" or "admin"

  Map<String, dynamic>? userData;

  bool get isLoggedIn => role != null;
  bool get isAdmin => role == 'admin';

  String? get currentUserDocId {
    final rawId = userData?['firestoreDocId'] ?? userData?['id'] ?? userData?['no'];
    return rawId?.toString();
  }

  void login(String r, {Map<String, dynamic>? data}) {
    role = r;
    userData = data;
    notifyListeners();
  }

  void updateUserData(Map<String, dynamic> newData) {
    userData = {
      ...?userData,
      ...newData,
    };
    notifyListeners();
  }

  void logout() {
    role = null;
    userData = null;
    notifyListeners();
  }
}