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
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Instructors", "Classrooms", "Events"];
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
      appBar: const CustomAppBar(title: "My Favorites", showBack: true),
      body: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) => AppFilterChip(
                label: _filters[index],
                active: _selectedFilter == _filters[index],
                onTap: () => setState(() => _selectedFilter = _filters[index]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _databaseFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return _buildEmptyState();
                final data = snapshot.data!;
                List<Widget> favoriteCards = [];

                for (String id in favIds) {
                  if (id.startsWith("class_") && (_selectedFilter == "All" || _selectedFilter == "Classrooms")) {
                    final matches = (data['classrooms'] as List).where((x) => "class_${x['id']}" == id);
                    if (matches.isNotEmpty) {
                      favoriteCards.add(InfoCard(title: matches.first['name'], subtitle: matches.first['building'], badge: const AppBadge(label: "Classroom"),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomDetailScreen(classroomData: matches.first))),
                      ));
                    }
                  } else if (id.startsWith("inst_") && (_selectedFilter == "All" || _selectedFilter == "Instructors")) {
                    final matches = (data['instructors'] as List).where((x) => "inst_${x['id']}" == id);
                    if (matches.isNotEmpty) {
                      favoriteCards.add(InfoCard(title: matches.first['name'], subtitle: matches.first['department'], badge: const AppBadge(label: "Instructor"),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InstructorDetailScreen(instructorData: matches.first))),
                      ));
                    }
                  }
                  // Event logic follows the same pattern...
                }
                return favoriteCards.isEmpty ? _buildEmptyState() : ListView(children: favoriteCards);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No favorites added yet.", style: TextStyle(color: AppTheme.textMuted)));
  }
}