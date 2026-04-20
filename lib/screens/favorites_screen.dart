import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/info_card.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart'; // JSON Servisi
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
  String _selectedFilter = "Tümü";
  final List<String> _filters = ["Tümü", "Hocalar", "Derslikler", "Etkinlikler"];
  late Future<Map<String, dynamic>> _databaseFuture;

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  @override
  Widget build(BuildContext context) {
    final favIds = context.watch<FavoritesProvider>().favorites;

    return Scaffold(
      appBar: const CustomAppBar(title: "Favorilerim", showBack: true),
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
                  onTap: () => setState(() => _selectedFilter = filter),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final data = snapshot.data!;
                List<Widget> favoriteCards = [];

                for (String id in favIds) {
                  if (id.startsWith("class_") && (_selectedFilter == "Tümü" || _selectedFilter == "Derslikler")) {
                    final classId = int.parse(id.split("_")[1]);
                    final c = (data['classrooms'] as List).firstWhere((x) => x['id'] == classId, orElse: () => null);
                    if (c != null) {
                      favoriteCards.add(InfoCard(
                        title: c['name'], subtitle: c['building'], badge: const AppBadge(label: "Derslik"),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroomData: c))),
                      ));
                    }
                  } else if (id.startsWith("inst_") && (_selectedFilter == "Tümü" || _selectedFilter == "Hocalar")) {
                    final instId = int.parse(id.split("_")[1]);
                    final i = (data['instructors'] as List).firstWhere((x) => x['id'] == instId, orElse: () => null);
                    if (i != null) {
                      favoriteCards.add(InfoCard(
                        title: i['name'], subtitle: i['department'], badge: const AppBadge(label: "Hoca"),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InstructorDetailScreen(instructorData: i))),
                      ));
                    }
                  } else if (id.startsWith("evt_") && (_selectedFilter == "Tümü" || _selectedFilter == "Etkinlikler")) {
                    final evtId = int.parse(id.split("_")[1]);
                    final e = (data['events'] as List).firstWhere((x) => x['id'] == evtId, orElse: () => null);
                    if (e != null) {
                      favoriteCards.add(InfoCard(
                        title: e['title'], subtitle: e['date'], badge: const AppBadge(label: "Etkinlik"),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventData: e))),
                      ));
                    }
                  }
                }

                if (favoriteCards.isEmpty) return _buildEmptyState();

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
          Icon(Icons.star_border, size: 64, color: AppTheme.borderColor),
          SizedBox(height: 16),
          Text("Henüz favori eklemediniz", style: TextStyle(fontSize: 18, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}