import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart';
import '../providers/favorites_provider.dart';

import 'classroom_detail_screen.dart';
import 'instructor_detail_screen.dart';
import 'event_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _selectedFilter = "All";

  final List<String> _filters = [
    "All",
    "Instructors",
    "Classrooms",
    "Events",
  ];

  late Future<Map<String, dynamic>> _databaseFuture;

  @override
  void initState() {
    super.initState();

    // Favorites should use fresh Firestore data because instructor/classroom/event
    // records may have been updated by admin.
    _databaseFuture = DataService.loadDatabase(forceRefresh: true);
  }

  Map<String, dynamic> _toStringDynamicMap(Map<dynamic, dynamic> source) {
    return source.map(
          (key, value) => MapEntry(key.toString(), value),
    );
  }

  String _normalize(dynamic value) {
    return value?.toString().trim() ?? "";
  }

  String _favoritePayload(String favoriteId, String prefix) {
    if (!favoriteId.startsWith(prefix)) return "";
    return favoriteId.substring(prefix.length).trim();
  }

  bool _matchesFavoriteId({
    required String favoriteId,
    required String prefix,
    required Map<dynamic, dynamic> item,
    required List<dynamic> candidateFields,
  }) {
    final payload = _favoritePayload(favoriteId, prefix);

    if (payload.isEmpty) {
      return false;
    }

    final candidates = <String>{
      for (final field in candidateFields)
        if (_normalize(field).isNotEmpty) _normalize(field),
      if (_normalize(item['id']).isNotEmpty) _normalize(item['id']),
      if (_normalize(item['firestoreDocId']).isNotEmpty)
        _normalize(item['firestoreDocId']),
      if (_normalize(item['docId']).isNotEmpty) _normalize(item['docId']),
    };

    return candidates.contains(payload);
  }

  bool _matchesInstructorFavorite(
      String favoriteId,
      Map<dynamic, dynamic> instructor,
      ) {
    return _matchesFavoriteId(
      favoriteId: favoriteId,
      prefix: "inst_",
      item: instructor,
      candidateFields: [
        instructor['id'],
        instructor['firestoreDocId'],
        instructor['docId'],
        instructor['email'],
        instructor['name'],
      ],
    );
  }

  bool _matchesClassroomFavorite(
      String favoriteId,
      Map<dynamic, dynamic> classroom,
      ) {
    return _matchesFavoriteId(
      favoriteId: favoriteId,
      prefix: "class_",
      item: classroom,
      candidateFields: [
        classroom['id'],
        classroom['firestoreDocId'],
        classroom['docId'],
        classroom['roomCode'],
        classroom['name'],
      ],
    );
  }

  bool _matchesEventFavorite(
      String favoriteId,
      Map<dynamic, dynamic> event,
      ) {
    return _matchesFavoriteId(
      favoriteId: favoriteId,
      prefix: "evt_",
      item: event,
      candidateFields: [
        event['id'],
        event['eventId'],
        event['firestoreDocId'],
        event['docId'],
        event['title'],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final favIds = context.watch<FavoritesProvider>().favorites;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "My Favorites",
        showBack: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];

                return AppFilterChip(
                  label: filter,
                  active: _selectedFilter == filter,
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _databaseFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final data = snapshot.data!;

                final instructors = (data['instructors'] as List<dynamic>? ?? [])
                    .whereType<Map<dynamic, dynamic>>()
                    .where((item) => !DataService.isDeletedRecord(item))
                    .toList();

                final classrooms = (data['classrooms'] as List<dynamic>? ?? [])
                    .whereType<Map<dynamic, dynamic>>()
                    .where((item) => !DataService.isDeletedRecord(item))
                    .toList();

                final events = (data['events'] as List<dynamic>? ?? [])
                    .whereType<Map<dynamic, dynamic>>()
                    .where((item) => !DataService.isDeletedRecord(item))
                    .toList();

                final favoriteCards = <Widget>[];

                for (final favoriteId in favIds) {
                  if (favoriteId.startsWith("inst_") &&
                      (_selectedFilter == "All" ||
                          _selectedFilter == "Instructors")) {
                    final matches = instructors.where(
                          (instructor) =>
                          _matchesInstructorFavorite(favoriteId, instructor),
                    );

                    if (matches.isNotEmpty) {
                      final instructor = matches.first;

                      favoriteCards.add(
                        InfoCard(
                          title: instructor['name']?.toString() ?? '',
                          subtitle:
                          instructor['department']?.toString() ?? '',
                          badge: const AppBadge(label: "Instructor"),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InstructorDetailScreen(
                                instructorData:
                                _toStringDynamicMap(instructor),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  } else if (favoriteId.startsWith("class_") &&
                      (_selectedFilter == "All" ||
                          _selectedFilter == "Classrooms")) {
                    final matches = classrooms.where(
                          (classroom) =>
                          _matchesClassroomFavorite(favoriteId, classroom),
                    );

                    if (matches.isNotEmpty) {
                      final classroom = matches.first;

                      favoriteCards.add(
                        InfoCard(
                          title: classroom['name']?.toString() ?? '',
                          subtitle: classroom['building']?.toString() ??
                              classroom['location']?.toString() ??
                              '',
                          badge: const AppBadge(label: "Classroom"),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassroomDetailScreen(
                                classroomData:
                                _toStringDynamicMap(classroom),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  } else if (favoriteId.startsWith("evt_") &&
                      (_selectedFilter == "All" ||
                          _selectedFilter == "Events")) {
                    final matches = events.where(
                          (event) => _matchesEventFavorite(favoriteId, event),
                    );

                    if (matches.isNotEmpty) {
                      final event = matches.first;

                      favoriteCards.add(
                        InfoCard(
                          title: event['title']?.toString() ?? '',
                          subtitle: event['date']?.toString() ?? '',
                          badge: const AppBadge(label: "Event"),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(
                                eventData: _toStringDynamicMap(event),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }

                if (favoriteCards.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: favoriteCards,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: 64,
            color: AppTheme.borderColor,
          ),
          SizedBox(height: 16),
          Text(
            "You haven't added any favorites yet",
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}