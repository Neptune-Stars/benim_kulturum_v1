import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../data/data_service.dart';

class CafeteriaMenuScreen extends StatefulWidget {
  final bool isRootTab;
  const CafeteriaMenuScreen({Key? key, this.isRootTab = false}) : super(key: key);

  @override
  State<CafeteriaMenuScreen> createState() => _CafeteriaMenuScreenState();
}

class _CafeteriaMenuScreenState extends State<CafeteriaMenuScreen> {
  late Future<Map<String, dynamic>> _databaseFuture;

  String _selectedCampus = "Ataköy";
  String _selectedDay = "Pazartesi";
  String _selectedMealType = "Öğle";

  final List<String> _days = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Hafta Sonu"];

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
      appBar: const CustomAppBar(title: "Yemekhane Menüsü", showBack: false),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _databaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final cafeteriaData = snapshot.data?['cafeteria'] as Map<dynamic, dynamic>? ?? {};
            final campuses = cafeteriaData['campuses'] as List<dynamic>? ?? ["Ataköy", "Şirinevler", "İncirli", "Basın Ekspres"];

            final menus = cafeteriaData['menus'] as Map<dynamic, dynamic>? ?? {};
            final campusMenus = menus[_selectedCampus] as Map<dynamic, dynamic>? ?? {};
            final dayMeals = campusMenus[_selectedDay] as Map<dynamic, dynamic>? ?? {};

            // YENİ: Öğün butonlarını DİNAMİK olarak oluşturuyoruz. Olmayan öğün çıkmaz.
            List<String> dynamicMealTypes = dayMeals.keys.map((e) => e.toString()).toList();

            // Mantıksal sıraya diz (Önce Kahvaltı, Sonra Öğle, vb.)
            final order = {"Kahvaltı": 1, "Öğle": 2, "Akşam": 3, "Fast Food": 4};
            dynamicMealTypes.sort((a, b) => (order[a] ?? 9).compareTo(order[b] ?? 9));

            // Eğer kullanıcının seçtiği öğün (örn: Akşam), o günkü kampüste yoksa
            // Hata vermemesi için mevcut olan ilk öğünü otomatik seç!
            String safeMealType = _selectedMealType;
            if (!dynamicMealTypes.contains(safeMealType) && dynamicMealTypes.isNotEmpty) {
              safeMealType = dynamicMealTypes.first;
              // Ekranda pırpır olmaması için State'i arka planda güvenle güncelliyoruz
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedMealType = safeMealType);
              });
            }

            final currentMenu = dayMeals[safeMealType] as Map<dynamic, dynamic>?;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildCampusSelector(campuses.cast<String>(), dividerColor),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildHorizontalSelector(_days, _selectedDay, (val) => setState(() => _selectedDay = val), textColor, dividerColor, cardColor),
                  ),
                ),

                // YENİ: Dinamik Öğün Seçici (Sadece var olanları gösterir)
                if (dynamicMealTypes.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _buildHorizontalSelector(dynamicMealTypes, safeMealType, (val) => setState(() => _selectedMealType = val), textColor, dividerColor, cardColor),
                    ),
                  ),

                if (currentMenu == null || dynamicMealTypes.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                          child: Text(
                              "$_selectedCampus Kampüsünde $_selectedDay günü için kayıtlı menü bulunmuyor.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textMuted)
                          )
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildMenuCard(safeMealType, currentMenu, textColor, dividerColor, cardColor),
                    ),
                  ),
              ],
            );
          }
      ),
    );
  }

  Widget _buildCampusSelector(List<String> campuses, Color dividerColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: dividerColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCampus,
          icon: const Icon(Icons.business, color: AppTheme.primaryColor),
          items: campuses.map((c) => DropdownMenuItem(value: c, child: Text("$c Kampüsü", style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          onChanged: (val) => setState(() => _selectedCampus = val!),
        ),
      ),
    );
  }

  Widget _buildHorizontalSelector(List<String> options, String currentValue, Function(String) onSelect, Color textColor, Color dividerColor, Color cardColor) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = currentValue == option;
          return GestureDetector(
            onTap: () => onSelect(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryColor : cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? AppTheme.primaryColor : dividerColor),
              ),
              alignment: Alignment.center,
              child: Text(
                option,
                style: TextStyle(
                  color: selected ? Colors.white : textColor,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(String mealName, Map<dynamic, dynamic> menu, Color textColor, Color dividerColor, Color cardColor) {
    final items = menu['items'] as List<dynamic>? ?? [];
    final bool isAlaCarte = menu['isAlaCarte'] == true;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(mealName == "Kahvaltı" ? Icons.free_breakfast : mealName == "Fast Food" ? Icons.fastfood : Icons.restaurant, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(mealName, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              if (!isAlaCarte && menu['price'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.successColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(menu['price'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Saat: ${menu['time'] ?? '-'}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 16),
          ...items.map((item) {
            String itemName = isAlaCarte ? item['name'] : item.toString();
            String itemPrice = isAlaCarte ? item['price'] : "";

            return Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: dividerColor.withOpacity(0.5))),
              child: Row(
                children: [
                  Icon(isAlaCarte ? Icons.local_dining : Icons.restaurant_menu, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(child: Text(itemName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor))),
                  if (isAlaCarte)
                    Text(itemPrice, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor, fontSize: 15))
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}