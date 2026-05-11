import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class JoinedEventsProvider extends ChangeNotifier {
  final Set<String> _joinedEventIds = <String>{};
  String? _studentDocId;
  bool _isLoaded = false;
  bool _isSaving = false;

  int get joinedCount => _joinedEventIds.length;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;

  List<String> get joinedEventIds {
    final items = _joinedEventIds.toList();
    items.sort();
    return items;
  }

  Future<void> loadForStudent({
    required String studentDocId,
    Map<String, dynamic>? userData,
  }) async {
    _studentDocId = studentDocId;
    _joinedEventIds.clear();

    final rawJoinedEvents = _readJoinedEventList(userData);
    _joinedEventIds.addAll(rawJoinedEvents.map(_normalizeEventId));

    _isLoaded = true;
    _isSaving = false;
    notifyListeners();
  }

  bool isJoined(dynamic eventId) {
    return _joinedEventIds.contains(_normalizeEventId(eventId));
  }

  Future<void> joinEvent(dynamic eventId) async {
    final normalizedId = _normalizeEventId(eventId);
    if (_joinedEventIds.add(normalizedId)) {
      notifyListeners();
      await _persistJoinedEventsSafely(
        rollback: () => _joinedEventIds.remove(normalizedId),
      );
    }
  }

  Future<void> leaveEvent(dynamic eventId) async {
    final normalizedId = _normalizeEventId(eventId);
    if (_joinedEventIds.remove(normalizedId)) {
      notifyListeners();
      await _persistJoinedEventsSafely(
        rollback: () => _joinedEventIds.add(normalizedId),
      );
    }
  }

  Future<void> toggleJoin(dynamic eventId) async {
    final normalizedId = _normalizeEventId(eventId);
    final wasJoined = _joinedEventIds.contains(normalizedId);

    if (wasJoined) {
      _joinedEventIds.remove(normalizedId);
    } else {
      _joinedEventIds.add(normalizedId);
    }

    notifyListeners();

    await _persistJoinedEventsSafely(
      rollback: () {
        if (wasJoined) {
          _joinedEventIds.add(normalizedId);
        } else {
          _joinedEventIds.remove(normalizedId);
        }
      },
    );
  }

  Future<void> _persistJoinedEventsSafely({required VoidCallback rollback}) async {
    try {
      await _persistJoinedEvents();
    } catch (error) {
      rollback();
      notifyListeners();
      debugPrint('Joined event could not be saved: $error');
    }
  }

  Future<void> _persistJoinedEvents() async {
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
          'joinedEventIds': joinedEventIds,
          'joinedEventsUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  List<dynamic> _readJoinedEventList(Map<String, dynamic>? userData) {
    final raw = userData?['joinedEventIds'] ?? userData?['joinedEvents'];
    if (raw is List) {
      return raw;
    }
    return <dynamic>[];
  }

  String _normalizeEventId(dynamic eventId) {
    return eventId?.toString() ?? '';
  }

  void reset() {
    _joinedEventIds.clear();
    _studentDocId = null;
    _isLoaded = false;
    _isSaving = false;
    notifyListeners();
  }
}
