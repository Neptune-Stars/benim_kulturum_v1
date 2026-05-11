import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = <String>{};
  String? _studentDocId;
  bool _isLoaded = false;
  bool _isSaving = false;

  List<String> get favorites {
    final items = _favoriteIds.toList();
    items.sort();
    return items;
  }

  int get favoriteCount => _favoriteIds.length;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;

  Future<void> loadForStudent({
    required String studentDocId,
    Map<String, dynamic>? userData,
  }) async {
    _studentDocId = studentDocId;
    _favoriteIds.clear();

    final rawFavorites = _readFavoriteList(userData);
    _favoriteIds.addAll(rawFavorites.map((item) => item.toString()));

    _isLoaded = true;
    _isSaving = false;
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favoriteIds.contains(id);
  }

  Future<void> toggleFavorite(String id) async {
    final wasFavorite = _favoriteIds.contains(id);

    if (wasFavorite) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }

    notifyListeners();

    try {
      await _persistFavorites();
    } catch (error) {
      if (wasFavorite) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
      notifyListeners();
      debugPrint('Favorite could not be saved: $error');
    }
  }

  Future<void> _persistFavorites() async {
    final studentDocId = _studentDocId;
    if (studentDocId == null || studentDocId.isEmpty) {
      return;
    }

    _isSaving = true;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(studentDocId)
          .set(
        {
          'favoriteIds': favorites,
          'favoritesUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  List<dynamic> _readFavoriteList(Map<String, dynamic>? userData) {
    final raw = userData?['favoriteIds'] ?? userData?['favorites'];
    if (raw is List) {
      return raw;
    }
    return <dynamic>[];
  }

  void reset() {
    _favoriteIds.clear();
    _studentDocId = null;
    _isLoaded = false;
    _isSaving = false;
    notifyListeners();
  }
}
