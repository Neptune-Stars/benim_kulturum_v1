import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _studentData;
  bool _isAdmin = false;

  Map<String, dynamic>? get studentData => _studentData;
  bool get isAdmin => _isAdmin;

  // Login logic (Update this based on your existing login)
  void login(Map<String, dynamic> data, bool adminStatus) {
    _studentData = data;
    _isAdmin = adminStatus;
    notifyListeners();
  }

  void logout() {
    _studentData = null;
    _isAdmin = false;
    notifyListeners();
  }

  // YENİ: Firebase'den güncel veriyi çekme (Profil resmi vb. için)
  Future<void> refreshStudentData() async {
    if (_studentData == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(_studentData!['id'].toString())
        .get();

    if (doc.exists) {
      _studentData = doc.data();
      notifyListeners();
    }
  }
}