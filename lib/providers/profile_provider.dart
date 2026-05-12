import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/data_service.dart';

class StudentAvatarOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const StudentAvatarOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class ProfileProvider extends ChangeNotifier {
  static const List<StudentAvatarOption> avatarOptions = [
    StudentAvatarOption(
      id: 'avatar_1',
      label: 'Student',
      icon: Icons.school_rounded,
      color: Color(0xFF2563EB),
    ),
    StudentAvatarOption(
      id: 'avatar_2',
      label: 'Books',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF7C3AED),
    ),
    StudentAvatarOption(
      id: 'avatar_3',
      label: 'Code',
      icon: Icons.code_rounded,
      color: Color(0xFF059669),
    ),
    StudentAvatarOption(
      id: 'avatar_4',
      label: 'Science',
      icon: Icons.science_rounded,
      color: Color(0xFFDC2626),
    ),
    StudentAvatarOption(
      id: 'avatar_5',
      label: 'Campus',
      icon: Icons.location_city_rounded,
      color: Color(0xFFF59E0B),
    ),
  ];

  String? _selectedAvatarId;
  bool _isSaving = false;
  String? _errorMessage;

  String? get selectedAvatarId => _selectedAvatarId;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  StudentAvatarOption get selectedAvatar {
    return avatarOptions.firstWhere(
          (avatar) => avatar.id == _selectedAvatarId,
      orElse: () => avatarOptions.first,
    );
  }

  bool get hasSelectedAvatar {
    return _selectedAvatarId != null && _selectedAvatarId!.isNotEmpty;
  }

  void initializeFromUserData(Map<String, dynamic>? userData) {
    final avatarId = userData?['profileAvatarId']?.toString();

    if (avatarId != null &&
        avatarId.isNotEmpty &&
        avatarOptions.any((avatar) => avatar.id == avatarId)) {
      _selectedAvatarId = avatarId;
    } else {
      _selectedAvatarId = null;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<void> selectAvatar({
    required String studentDocId,
    required String avatarId,
  }) async {
    if (!avatarOptions.any((avatar) => avatar.id == avatarId)) {
      throw Exception('Invalid avatar option.');
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(studentDocId)
          .set(
        {
          'profileAvatarId': avatarId,
          'profileAvatarUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      DataService.clearCollectionCache('students');
      _selectedAvatarId = avatarId;
    } catch (e) {
      _errorMessage = 'Avatar could not be saved.';
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> removeAvatar({
    required String studentDocId,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(studentDocId)
          .set(
        {
          'profileAvatarId': FieldValue.delete(),
          'profileAvatarUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      DataService.clearCollectionCache('students');
      _selectedAvatarId = null;
    } catch (e) {
      _errorMessage = 'Avatar could not be removed.';
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    _selectedAvatarId = null;
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();
  }
}