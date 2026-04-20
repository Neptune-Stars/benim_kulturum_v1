import 'package:flutter/material.dart';

class JoinedEventsProvider extends ChangeNotifier {
  final Set<int> _joinedEventIds = {};

  int get joinedCount => _joinedEventIds.length;

  bool isJoined(int eventId) {
    return _joinedEventIds.contains(eventId);
  }

  List<int> get joinedEventIds => _joinedEventIds.toList()..sort();

  void joinEvent(int eventId) {
    if (_joinedEventIds.add(eventId)) {
      notifyListeners();
    }
  }

  void leaveEvent(int eventId) {
    if (_joinedEventIds.remove(eventId)) {
      notifyListeners();
    }
  }

  void toggleJoin(int eventId) {
    if (_joinedEventIds.contains(eventId)) {
      _joinedEventIds.remove(eventId);
    } else {
      _joinedEventIds.add(eventId);
    }
    notifyListeners();
  }
}