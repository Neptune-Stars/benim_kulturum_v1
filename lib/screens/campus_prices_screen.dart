import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/filter_chip_widget.dart';
import '../data/data_service.dart';

class CampusPricesScreen extends StatefulWidget {
  const CampusPricesScreen({Key? key}) : super(key: key);

  @override
  State<CampusPricesScreen> createState() => _CampusPricesScreenState();
}

class _CampusPricesScreenState extends State<CampusPricesScreen> {
  String _selectedCategory = "Tea/Coffee";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _categories = ["Tea/Coffee", "Beverages", "Snacks", "Meals"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final dividerColor = Theme.of(context).dividerColor;

    return Scaffold(
      appBar: const CustomAppBar(title: "Campus Prices", showBack: true),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!['prices'] == null) {
              return const Center(child: Text("Price data not found."));
            }

            final allPrices = snapshot.data!['prices'] as List<dynamic>? ?? [];
            final items = allPrices.where((p) => p['category'] == _selectedCategory).toList();

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return AppFilterChip(
                          label: category,
                          active: _selectedCategory == category,
                          onTap: () => setState(() => _selectedCategory = category),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: dividerColor)),
                      child: items.isEmpty
                          ? const Center(child: Text("No products in this category.", style: TextStyle(color: AppTheme.textMuted)))
                          : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(color: dividerColor, height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(child: Text(item["name"] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor))),
                                Text(item["price"] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
      ),
    );
  }
}