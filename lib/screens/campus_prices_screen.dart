import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/filter_chip_widget.dart';

class CampusPricesScreen extends StatefulWidget {
  const CampusPricesScreen({Key? key}) : super(key: key);

  @override
  State<CampusPricesScreen> createState() => _CampusPricesScreenState();
}

class _CampusPricesScreenState extends State<CampusPricesScreen> {
  String _selectedCategory = "Çay/Kahve";

  final List<String> _categories = [
    "Çay/Kahve",
    "İçecekler",
    "Atıştırmalıklar",
    "Paketli Ürünler",
  ];

  final Map<String, List<Map<String, String>>> _priceData = {
    "Çay/Kahve": [
      {"name": "Çay", "price": "₺3"},
      {"name": "Türk Kahvesi", "price": "₺12"},
      {"name": "Nescafe", "price": "₺8"},
      {"name": "Cappuccino", "price": "₺15"},
      {"name": "Latte", "price": "₺15"},
      {"name": "Espresso", "price": "₺10"},
      {"name": "Sıcak Çikolata", "price": "₺12"},
    ],
    "İçecekler": [
      {"name": "Su (0.5L)", "price": "₺3"},
      {"name": "Ayran", "price": "₺5"},
      {"name": "Kola (330ml)", "price": "₺12"},
      {"name": "Fanta", "price": "₺12"},
      {"name": "Sprite", "price": "₺12"},
      {"name": "Ice Tea", "price": "₺10"},
      {"name": "Meyve Suyu (200ml)", "price": "₺8"},
      {"name": "Soğuk Kahve", "price": "₺18"},
    ],
    "Atıştırmalıklar": [
      {"name": "Poğaça", "price": "₺8"},
      {"name": "Simit", "price": "₺5"},
      {"name": "Tost", "price": "₺15"},
      {"name": "Sandviç", "price": "₺20"},
      {"name": "Börek", "price": "₺12"},
      {"name": "Waffle", "price": "₺25"},
      {"name": "Kurabiye", "price": "₺5"},
      {"name": "Cips", "price": "₺8"},
    ],
    "Paketli Ürünler": [
      {"name": "Ülker Laviva", "price": "₺18"},
      {"name": "Albeni", "price": "₺16"},
      {"name": "Metro", "price": "₺20"},
      {"name": "Ülker Gofret", "price": "₺15"},
      {"name": "Hoşbeş", "price": "₺14"},
      {"name": "Tutku", "price": "₺17"},
      {"name": "Browni Intense", "price": "₺19"},
      {"name": "Cornetto", "price": "₺35"},
      {"name": "Algida", "price": "₺32"},
      {"name": "Magnum", "price": "₺45"},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final items = _priceData[_selectedCategory] ?? [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final dividerColor = Theme.of(context).dividerColor;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Kampüs Fiyatları",
        showBack: true,
      ),
      body: Padding(
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
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dividerColor),
                ),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: dividerColor, height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item["name"]!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                          Text(
                            item["price"]!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Son güncelleme: 18 Nisan 2026",
              style: TextStyle(
                color: mutedColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}