import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../data/data_service.dart';

class CampusPricesScreen extends StatefulWidget {
  const CampusPricesScreen({Key? key}) : super(key: key);

  @override
  State<CampusPricesScreen> createState() => _CampusPricesScreenState();
}

class _CampusPricesScreenState extends State<CampusPricesScreen> {
  late Future<Map<String, dynamic>> _databaseFuture;
  String _searchQuery = "";
  String _selectedFilter = "Tümü";

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
      appBar: const CustomAppBar(title: "Kafe ve Kantin Fiyatları", showBack: true),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final pricesList = snapshot.data?['prices'] as List<dynamic>? ?? [];

            // YENİ: Firebase'den gelen verilere göre kategorileri DİNAMİK olarak oluştur
            Set<String> categorySet = {"Tümü"};
            for (var item in pricesList) {
              if (item['category'] != null) {
                categorySet.add(item['category'].toString());
              }
            }
            List<String> dynamicFilters = categorySet.toList();

            // Arama ve filtreleme işlemi
            final filteredPrices = pricesList.where((p) {
              final name = p['name']?.toString() ?? "";
              final category = p['category']?.toString() ?? "";

              final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesFilter = _selectedFilter == "Tümü" || category == _selectedFilter;

              return matchesSearch && matchesFilter;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AppSearchBar(
                    placeholder: "Ürün ara (Çay, Kahve, Tost...)",
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                // Dinamik Filtreler
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: dynamicFilters.length,
                    itemBuilder: (context, index) {
                      final filter = dynamicFilters[index];
                      return AppFilterChip(
                        label: filter,
                        active: _selectedFilter == filter,
                        onTap: () => setState(() => _selectedFilter = filter),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Fiyat Listesi
                Expanded(
                  child: filteredPrices.isEmpty
                      ? Center(child: Text("Ürün bulunamadı.", style: TextStyle(color: AppTheme.textMuted)))
                      : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: filteredPrices.length,
                    separatorBuilder: (context, index) => Divider(color: dividerColor, height: 1),
                    itemBuilder: (context, index) {
                      final item = filteredPrices[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_cafe_outlined, color: AppTheme.primaryColor),
                        ),
                        title: Text(
                          item['name']?.toString() ?? "",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                        ),
                        subtitle: Text(
                          item['category']?.toString() ?? "",
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                        trailing: Text(
                          item['price']?.toString() ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.successColor),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
      ),
    );
  }
}