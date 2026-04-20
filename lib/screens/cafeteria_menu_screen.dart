import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';
import '../data/data_service.dart'; // JSON Servisi

class CafeteriaMenuScreen extends StatefulWidget {
  const CafeteriaMenuScreen({Key? key}) : super(key: key);

  @override
  State<CafeteriaMenuScreen> createState() => _CafeteriaMenuScreenState();
}

class _CafeteriaMenuScreenState extends State<CafeteriaMenuScreen> {
  int _currentDateIndex = 0;
  String _selectedMeal = "Öğle";
  late Future<Map<String, dynamic>> _databaseFuture;

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  void _changeDate(int delta, int maxIndex) {
    setState(() {
      _currentDateIndex = (_currentDateIndex + delta).clamp(0, maxIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Yemekhane Menüsü", showBack: true),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!['cafeteria'] == null) {
              return const Center(child: Text("Menü verisi bulunamadı."));
            }

            final cafeteriaData = snapshot.data!['cafeteria'];
            final dates = (cafeteriaData['dates'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
            final mealTypes = (cafeteriaData['mealTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
            final menus = cafeteriaData['menus'] as Map<String, dynamic>? ?? {};

            if (dates.isEmpty || mealTypes.isEmpty || menus.isEmpty) {
              return const Center(child: Text("Eksik menü verisi."));
            }

            // Güvenli okuma
            if (!mealTypes.contains(_selectedMeal)) {
              _selectedMeal = mealTypes.first;
            }

            final currentMenu = menus[_selectedMeal] ?? {};
            final items = (currentMenu['items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
            final isChips = currentMenu['isChips'] == true;

            return Column(
              children: [
                // Date Navigator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentDateIndex > 0 ? () => _changeDate(-1, dates.length - 1) : null,
                        color: _currentDateIndex > 0 ? AppTheme.textPrimary : AppTheme.borderColor,
                      ),
                      Text(dates[_currentDateIndex], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentDateIndex < dates.length - 1 ? () => _changeDate(1, dates.length - 1) : null,
                        color: _currentDateIndex < dates.length - 1 ? AppTheme.textPrimary : AppTheme.borderColor,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Meal Tabs
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: mealTypes.map((meal) {
                      final isActive = _selectedMeal == meal;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMeal = meal),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isActive ? AppTheme.primaryColor : AppTheme.borderColor),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              meal,
                              style: TextStyle(
                                color: isActive ? Colors.white : AppTheme.textPrimary,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Menu Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${currentMenu['time'] ?? ''}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                                AppBadge(label: currentMenu['price'] ?? '', backgroundColor: AppTheme.successColor, textColor: Colors.white),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (isChips)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: items.map((item) => Chip(
                                  label: Text(item),
                                  backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                                  side: BorderSide.none,
                                )).toList(),
                              )
                            else
                              Expanded(
                                child: ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.restaurant_menu, size: 18, color: AppTheme.primaryColor),
                                        const SizedBox(width: 12),
                                        Text(items[index], style: const TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Info Note
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Menü değişiklik gösterebilir. Güncel bilgi için yemekhaneyi ziyaret ediniz.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              ],
            );
          }
      ),
    );
  }
}