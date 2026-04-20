import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  static const String _profileImageKey = 'profile_image_path';

  String? _profileImagePath;

  String? get profileImagePath => _profileImagePath;

  bool get hasProfileImage =>
      _profileImagePath != null && _profileImagePath!.isNotEmpty;

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_profileImageKey);

    if (savedPath != null && savedPath.isNotEmpty) {
      final file = File(savedPath);
      if (await file.exists()) {
        _profileImagePath = savedPath;
      } else {
        _profileImagePath = null;
        await prefs.remove(_profileImageKey);
      }
    } else {
      _profileImagePath = null;
    }

    notifyListeners();
  }

  Future<void> pickProfileImageFromGallery() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (pickedFile == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(pickedFile.path).copy(
      '${appDir.path}/$fileName',
    );

    _profileImagePath = savedImage.path;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, _profileImagePath!);

    notifyListeners();
  }

  Future<void> removeProfileImage() async {
    if (_profileImagePath != null) {
      final file = File(_profileImagePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _profileImagePath = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileImageKey);

    notifyListeners();
  }
}