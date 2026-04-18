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

  final List<String> _categories = ["Çay/Kahve", "İçecekler", "Atıştırmalıklar", "Yemek"];

  final Map<String, List<Map<String, String>>> _priceData = {
    "Çay/Kahve": [
      {"name": "Çay", "price": "₺3"}, {"name": "Türk Kahvesi", "price": "₺12"},
      {"name": "Nescafe", "price": "₺8"}, {"name": "Cappuccino", "price": "₺15"},
      {"name": "Latte", "price": "₺15"}, {"name": "Espresso", "price": "₺10"},
      {"name": "Sıcak Çikolata", "price": "₺12"}
    ],
    "İçecekler": [
      {"name": "Su (0.5L)", "price": "₺3"}, {"name": "Ayran", "price": "₺5"},
      {"name": "Kola (330ml)", "price": "₺12"}, {"name": "Fanta", "price": "₺12"},
      {"name": "Sprite", "price": "₺12"}, {"name": "Ice Tea", "price": "₺10"},
      {"name": "Meyve Suyu (200ml)", "price": "₺8"}, {"name": "Soğuk Kahve", "price": "₺18"}
    ],
    "Atıştırmalıklar": [
      {"name": "Poğaça", "price": "₺8"}, {"name": "Simit", "price": "₺5"},
      {"name": "Tost", "price": "₺15"}, {"name": "Sandviç", "price": "₺20"},
      {"name": "Börek", "price": "₺12"}, {"name": "Waffle", "price": "₺25"},
      {"name": "Kurabiye", "price": "₺5"}, {"name": "Çikolata", "price": "₺10"},
      {"name": "Cips", "price": "₺8"}
    ],
    "Yemek": [
      {"name": "Kahvaltı Tabağı", "price": "₺25"}, {"name": "Öğle Menüsü", "price": "₺35"},
      {"name": "Akşam Menüsü", "price": "₺35"}, {"name": "Pizza (dilim)", "price": "₺20"},
      {"name": "Lahmacun", "price": "₺15"}, {"name": "Döner", "price": "₺40"},
      {"name": "Pilav Üstü", "price": "₺30"}
    ]
  };

  @override
  Widget build(BuildContext context) {
    final items = _priceData[_selectedCategory]!;

    return Scaffold(
      appBar: const CustomAppBar(title: "Kampüs Fiyatları", showBack: true),
      body: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
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
                child: ListView.separated(
                  padding: const EdgeInsets.all(0),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item["name"]!, style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Text(
                        item["price"]!,
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
      ),
    );
  }
}