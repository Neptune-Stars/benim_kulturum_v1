import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/filter_chip_widget.dart';
import '../data/data_service.dart'; // JSON Servisi

class CampusPricesScreen extends StatefulWidget {
  const CampusPricesScreen({Key? key}) : super(key: key);

  @override
  State<CampusPricesScreen> createState() => _CampusPricesScreenState();
}

class _CampusPricesScreenState extends State<CampusPricesScreen> {
  String _selectedCategory = "Çay/Kahve";
  late Future<Map<String, dynamic>> _databaseFuture;

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Kampüs Fiyatları", showBack: true),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!['campusPrices'] == null) {
              return const Center(child: Text("Fiyat verisi bulunamadı."));
            }

            final pricesData = snapshot.data!['campusPrices'];
            final categories = (pricesData['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
            final itemsMap = pricesData['items'] as Map<String, dynamic>? ?? {};

            if (categories.isEmpty) {
              return const Center(child: Text("Kategori bulunamadı."));
            }

            if (!categories.contains(_selectedCategory)) {
              _selectedCategory = categories.first;
            }

            final currentItems = (itemsMap[_selectedCategory] as List<dynamic>?) ?? [];

            return Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return AppFilterChip(
                        label: cat,
                        active: _selectedCategory == cat,
                        onTap: () => setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      child: currentItems.isEmpty
                          ? const Center(child: Text("Bu kategoriye ait ürün bulunamadı."))
                          : ListView.separated(
                        padding: const EdgeInsets.all(0),
                        itemCount: currentItems.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = currentItems[index];
                          return ListTile(
                            title: Text(item["name"]?.toString() ?? "", style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: Text(
                              item["price"]?.toString() ?? "",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Son güncelleme: 18 Nisan 2026",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                )
              ],
            );
          }
      ),
    );
  }
}