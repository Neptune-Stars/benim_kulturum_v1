import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/badge_widget.dart';

class CafeteriaMenuScreen extends StatefulWidget {
  const CafeteriaMenuScreen({Key? key}) : super(key: key);

  @override
  State<CafeteriaMenuScreen> createState() => _CafeteriaMenuScreenState();
}

class _CafeteriaMenuScreenState extends State<CafeteriaMenuScreen> {
  int _currentDateIndex = 0;
  String _selectedMeal = "Öğle";

  final List<String> _dates = [
    "18 Nisan (Cumartesi)",
    "19 Nisan (Pazar)",
    "20 Nisan (Pazartesi)",
    "21 Nisan (Salı)",
    "22 Nisan (Çarşamba)"
  ];

  final List<String> _meals = ["Kahvaltı", "Öğle", "Akşam"];

  // Mock Menu Data
  final Map<String, Map<String, dynamic>> _menuData = {
    "Kahvaltı": {
      "time": "08:00-10:00",
      "price": "₺25",
      "items": ["Peynir", "Zeytin", "Domates", "Salatalık", "Reçel", "Tereyağı", "Haşlanmış yumurta", "Çay"],
      "isChips": true,
    },
    "Öğle": {
      "time": "12:00-14:00",
      "price": "₺35",
      "items": ["Mercimek Çorbası", "Tavuk Şinitzel", "Pilav", "Mevsim Salata", "Sütlaç", "Ayran"],
      "isChips": false,
    },
    "Akşam": {
      "time": "18:00-20:00",
      "price": "₺35",
      "items": ["Ezogelin Çorbası", "Karnıyarık", "Bulgur Pilavı", "Çoban Salata", "Meyve", "Ayran"],
      "isChips": false,
    }
  };

  void _changeDate(int delta) {
    setState(() {
      _currentDateIndex = (_currentDateIndex + delta).clamp(0, _dates.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = _menuData[_selectedMeal]!;
    final items = menu["items"] as List<String>;
    final isChips = menu["isChips"] as bool;

    return Scaffold(
      appBar: const CustomAppBar(title: "Yemekhane Menüsü", showBack: true),
      body: Column(
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
                  onPressed: _currentDateIndex > 0 ? () => _changeDate(-1) : null,
                  color: _currentDateIndex > 0 ? AppTheme.textPrimary : AppTheme.borderColor,
                ),
                Text(_dates[_currentDateIndex], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentDateIndex < _dates.length - 1 ? () => _changeDate(1) : null,
                  color: _currentDateIndex < _dates.length - 1 ? AppTheme.textPrimary : AppTheme.borderColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Meal Tabs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: _meals.map((meal) {
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
                          Text("${menu['time']}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                          AppBadge(label: menu['price'], backgroundColor: AppTheme.successColor, textColor: Colors.white),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Menü değişiklik gösterebilir. Güncel bilgi için yemekhaneyi ziyaret ediniz.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          )
        ],
      ),
    );
  }
}