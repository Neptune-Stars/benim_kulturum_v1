import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../data/data_service.dart';

class CafeteriaMenuScreen extends StatefulWidget {
  const CafeteriaMenuScreen({Key? key}) : super(key: key);

  @override
  State<CafeteriaMenuScreen> createState() => _CafeteriaMenuScreenState();
}

class _CafeteriaMenuScreenState extends State<CafeteriaMenuScreen> {
  String _selectedTab = "Öğle";
  late Future<Map<String, dynamic>> _databaseFuture;

  final List<String> _tabs = ["Kahvaltı", "Öğle", "Akşam", "Fast Food"];

  @override
  void initState() {
    super.initState();
    _databaseFuture = DataService.loadDatabase();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final dividerColor = Theme.of(context).dividerColor;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: const CustomAppBar(title: "Yemekhane Menüsü", showBack: true),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final cafeteriaData = snapshot.data?['cafeteria'] as Map<dynamic, dynamic>? ?? {};
            final menus = cafeteriaData['menus'] as Map<dynamic, dynamic>? ?? {};
            final currentMenu = menus[_selectedTab] as Map<dynamic, dynamic>?;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopInfoCard(),
                  const SizedBox(height: 16),
                  _buildTabSelector(textColor, dividerColor, cardColor),
                  const SizedBox(height: 16),
                  if (currentMenu == null)
                    Center(child: Text("Bu öğün için menü bulunamadı.", style: TextStyle(color: textColor)))
                  else
                    _buildMenuCard(currentMenu, textColor, dividerColor, cardColor),
                ],
              ),
            );
          }
      ),
    );
  }

  Widget _buildTopInfoCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.restaurant_menu, color: Colors.white), SizedBox(width: 10), Text("Kampüs Yemek Bilgisi", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))]),
          SizedBox(height: 8),
          Text("Admin panelinden güncellenen canlı menü verisi.", style: TextStyle(color: Colors.white70, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildTabSelector(Color textColor, Color dividerColor, Color cardColor) {
    return Row(
      children: _tabs.map((tab) {
        final selected = _selectedTab == tab;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: selected ? AppTheme.primaryColor : cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppTheme.primaryColor : dividerColor)),
                alignment: Alignment.center,
                child: Text(tab, style: TextStyle(color: selected ? Colors.white : textColor, fontWeight: selected ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMenuCard(Map<dynamic, dynamic> menu, Color textColor, Color dividerColor, Color cardColor) {
    final items = menu['items'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(menu['time'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 15, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.successColor, borderRadius: BorderRadius.circular(12)),
                child: Text(menu['price'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: dividerColor.withOpacity(0.7))),
            child: Row(
              children: [
                const Icon(Icons.fastfood, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(child: Text(item.toString(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}