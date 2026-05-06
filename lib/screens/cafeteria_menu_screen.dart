import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class CafeteriaMenuScreen extends StatefulWidget {
  final bool showBackButton;
  const CafeteriaMenuScreen({Key? key, this.showBackButton = true}) : super(key: key);

  @override
  State<CafeteriaMenuScreen> createState() => _CafeteriaMenuScreenState();
}

class _CafeteriaMenuScreenState extends State<CafeteriaMenuScreen> {
  late DateTime _selectedDate;
  late String _selectedTab;
  late Future<void> _ensureDailyFuture;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTab = DataService.defaultMealTypeForDate(_selectedDate);
    _ensureDailyFuture = DataService.ensureDailyCafeteriaMenus(_selectedDate);
  }

  void _changeDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTab = DataService.defaultMealTypeForDate(date);
      _ensureDailyFuture = DataService.ensureDailyCafeteriaMenus(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final dividerColor = Theme.of(context).dividerColor;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Cafeteria Menu",
        showBack: widget.showBackButton,
      ),
      body: FutureBuilder<void>(
        future: _ensureDailyFuture,
        builder: (context, ensureSnapshot) {
          if (ensureSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ensureSnapshot.hasError) {
            return Center(
              child: Text(
                "Error preparing menu data.",
                style: TextStyle(color: textColor),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('cafeteriaMenus')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error fetching menu data.",
                    style: TextStyle(color: textColor),
                  ),
                );
              }

              final dateKey = DataService.formatDateKey(_selectedDate);
              final menusByType = <String, Map<String, dynamic>>{};
              bool hasDayData = false;
              bool isDayActive = true;

              for (final doc in snapshot.data?.docs ?? []) {
                final data = doc.data();
                if (data['date'] == dateKey &&
                    data['campus'] == DataService.defaultCampus) {
                  hasDayData = true;

                  if (data['isDayActive'] == false) {
                    isDayActive = false;
                  }

                  final mealType = data['mealType']?.toString() ?? '';
                  final visible = data['isDayActive'] != false && data['isActive'] != false;

                  if (mealType.isNotEmpty && visible) {
                    menusByType[mealType] = data;
                  }
                }
              }

              if (!hasDayData) {
                isDayActive = true;
              }

              final activeMealTypes = DataService.cafeteriaMealTypes
                  .where((type) => menusByType.containsKey(type))
                  .toList();

              final defaultTab = DataService.defaultMealTypeForDate(_selectedDate);
              final selectedTab = activeMealTypes.contains(_selectedTab)
                  ? _selectedTab
                  : (activeMealTypes.contains(defaultTab)
                  ? defaultTab
                  : (activeMealTypes.isNotEmpty ? activeMealTypes.first : defaultTab));

              final currentMenu = menusByType[selectedTab];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDayActive) ...[
                      _buildTopInfoCard(_selectedDate, isDayActive),
                      const SizedBox(height: 16),
                    ],
                    _buildWeekDateSelector(textColor, dividerColor, cardColor),
                    const SizedBox(height: 16),
                    if (isDayActive && activeMealTypes.isNotEmpty) ...[
                      _buildTabSelector(
                        activeMealTypes,
                        selectedTab,
                        textColor,
                        dividerColor,
                        cardColor,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!isDayActive)
                      _buildEmptyState(
                        "No cafeteria service today.",
                        "",
                        textColor,
                        cardColor,
                        dividerColor,
                      )
                    else if (currentMenu == null)
                      _buildEmptyState(
                        "No active menu for today.",
                        "Menus activated in the admin panel will appear here.",
                        textColor,
                        cardColor,
                        dividerColor,
                      )
                    else
                      _buildMenuCard(
                        currentMenu,
                        textColor,
                        dividerColor,
                        cardColor,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopInfoCard(DateTime selectedDate, bool isDayActive) {
    final weekend = DataService.isWeekend(selectedDate);
    final title = !isDayActive
        ? "No Cafeteria Service Today"
        : (weekend ? "Weekend Fast Food Info" : "Campus Meal Info");
    final description = !isDayActive
        ? "The selected day is marked as closed by the admin. Menu is not shown to students."
        : (weekend
        ? "The selected day is a weekend. If active, Fast Food options are shown by default."
        : "The selected day is a weekday. Campus meal is shown from active menus.");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDateSelector(
      Color textColor,
      Color dividerColor,
      Color cardColor,
      ) {
    final weekStart = DataService.startOfWeek(_selectedDate);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = DataService.formatDateKey(day) ==
              DataService.formatDateKey(_selectedDate);
          final weekend = DataService.isWeekend(day);

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _changeDate(day),
            child: Container(
              width: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryColor : cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppTheme.primaryColor : dividerColor,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DataService.weekdayName(day.weekday),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: selected ? Colors.white70 : AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  if (weekend) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Fast Food",
                      style: TextStyle(
                        color: selected ? Colors.white : AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabSelector(
      List<String> tabs,
      String selectedTab,
      Color textColor,
      Color dividerColor,
      Color cardColor,
      ) {
    return Row(
      children: tabs.map((tab) {
        final selected = selectedTab == tab;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryColor : cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primaryColor : dividerColor,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab,
                  style: TextStyle(
                    color: selected ? Colors.white : textColor,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(
      String title,
      String subtitle,
      Color textColor,
      Color cardColor,
      Color dividerColor,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          if (subtitle.trim().isNotEmpty) ...[
            const Icon(
              Icons.info_outline,
              color: AppTheme.textMuted,
              size: 32,
            ),
            const SizedBox(height: 10),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuCard(
      Map<String, dynamic> menu,
      Color textColor,
      Color dividerColor,
      Color cardColor,
      ) {
    final items = menu['items'] as List<dynamic>? ?? [];
    String menuName = menu['menuName']?.toString() ?? "Menu";
    final mealType = menu['mealType']?.toString() ?? "";
    final isFastFood = mealType == "Fast Food";

    // YENİ EKLENEN KISIM: Başlığı seçilen güne göre dinamik hale getiriyoruz
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    // Eğer menü adı "Today's Meal" ise ve seçili gün bugün değilse, günün adını yaz
    if (menuName == "Today's Meal" && !isToday) {
      menuName = "${DataService.weekdayName(_selectedDate.weekday)}'s Meal";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            menuName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  menu['time']?.toString() ?? "-",
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  menu['price']?.toString() ?? "-",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            Text(
              "No food information in this menu.",
              style: TextStyle(color: textColor),
            )
          else
            ...items.map(
                  (item) {
                final bool itemHasPrice = item is Map;
                final itemName = itemHasPrice
                    ? (item['name']?.toString() ?? '')
                    : item.toString();
                final itemPrice = itemHasPrice ? item['price']?.toString() ?? '' : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: dividerColor.withOpacity(0.7)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFastFood ? Icons.local_dining : Icons.fastfood,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          itemName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (itemPrice.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            itemPrice,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}