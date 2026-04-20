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
  final List<String> _campuses = const [
    "Ataköy",
    "Şirinevler",
    "Basın\nEkspres",
    "İncirli",
  ];

  final List<String> _tabs = const [
    "Kahvaltı",
    "Günün Menüsü",
    "Fast Food",
  ];

  int _selectedCampusIndex = 0;
  String _selectedTab = "Günün Menüsü";
  DateTime _selectedDate = DateTime.now();

  final List<List<String>> _breakfastRotation = [
    [
      "Beyaz Peynir",
      "Zeytin",
      "Domates & Salatalık",
      "Haşlanmış Yumurta",
      "Bal & Tereyağı",
      "Çay",
    ],
    [
      "Kaşar Peyniri",
      "Zeytin",
      "Domates",
      "Omlet",
      "Reçel",
      "Çay",
    ],
    [
      "Beyaz Peynir",
      "Salam",
      "Salatalık",
      "Sahanda Yumurta",
      "Tereyağı",
      "Çay",
    ],
  ];

  final List<List<String>> _dailyRotation = [
    [
      "Mercimek Çorbası",
      "Tavuk Şinitzel",
      "Pilav",
      "Mevsim Salata",
      "Sütlaç",
      "Ayran",
    ],
    [
      "Ezogelin Çorbası",
      "Izgara Köfte",
      "Makarna",
      "Çoban Salata",
      "Revani",
      "Ayran",
    ],
    [
      "Düğün Çorbası",
      "Et Sote",
      "Bulgur Pilavı",
      "Yoğurt",
      "Meyve",
      "Ayran",
    ],
    [
      "Domates Çorbası",
      "Fırında Tavuk",
      "Pirinç Pilavı",
      "Salata",
      "Kemalpaşa",
      "Ayran",
    ],
    [
      "Yayla Çorbası",
      "Kuru Köfte",
      "Patates Püresi",
      "Mevsim Salata",
      "Supangle",
      "Ayran",
    ],
  ];

  final Map<String, List<Map<String, String>>> _fastFoodMenus = {
    "Ataköy": [
      {"name": "Izgara Köfte Menü", "price": "₺95"},
      {"name": "Tavuk Şinitzel Menü", "price": "₺90"},
      {"name": "Penne Makarna", "price": "₺70"},
      {"name": "Patates Kızartması", "price": "₺45"},
      {"name": "Kaşarlı Tost", "price": "₺60"},
    ],
    "Şirinevler": [
      {"name": "Hamburger Menü", "price": "₺90"},
      {"name": "Tavuk Şinitzel Menü", "price": "₺88"},
      {"name": "Fırın Makarna", "price": "₺72"},
      {"name": "Patates Kızartması", "price": "₺45"},
      {"name": "Karışık Tost", "price": "₺68"},
    ],
    "Basın\nEkspres": [
      {"name": "Chicken Burger Menü", "price": "₺85"},
      {"name": "Izgara Köfte Menü", "price": "₺95"},
      {"name": "Napoliten Makarna", "price": "₺72"},
      {"name": "Patates Kızartması", "price": "₺45"},
      {"name": "Sosisli Sandviç", "price": "₺68"},
    ],
    "İncirli": [
      {"name": "Tavuk Şinitzel Menü", "price": "₺90"},
      {"name": "Izgara Köfte Menü", "price": "₺95"},
      {"name": "Kremalı Makarna", "price": "₺74"},
      {"name": "Patates Kızartması", "price": "₺45"},
      {"name": "Karışık Tost", "price": "₺68"},
    ],
  };

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  List<DateTime> _getWeekDays(DateTime baseDate) {
    final monday = baseDate.subtract(Duration(days: baseDate.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _monthName(int month) {
    const months = [
      "Ocak",
      "Şubat",
      "Mart",
      "Nisan",
      "Mayıs",
      "Haziran",
      "Temmuz",
      "Ağustos",
      "Eylül",
      "Ekim",
      "Kasım",
      "Aralık",
    ];
    return months[month - 1];
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case 1:
        return "Pzt";
      case 2:
        return "Sal";
      case 3:
        return "Çar";
      case 4:
        return "Per";
      case 5:
        return "Cum";
      case 6:
        return "Cmt";
      case 7:
        return "Paz";
      default:
        return "";
    }
  }

  String _weekdayLong(int weekday) {
    switch (weekday) {
      case 1:
        return "Pazartesi";
      case 2:
        return "Salı";
      case 3:
        return "Çarşamba";
      case 4:
        return "Perşembe";
      case 5:
        return "Cuma";
      case 6:
        return "Cumartesi";
      case 7:
        return "Pazar";
      default:
        return "";
    }
  }

  String _fullDateLabel(DateTime date) {
    return "${date.day} ${_monthName(date.month)} ${date.year} • ${_weekdayLong(date.weekday)}";
  }

  List<String> _getBreakfastMenu() {
    final index =
        (_selectedDate.day + _selectedCampusIndex) % _breakfastRotation.length;
    return _breakfastRotation[index];
  }

  List<String> _getDailyMenu() {
    final index =
        (_selectedDate.day + _selectedCampusIndex) % _dailyRotation.length;
    return _dailyRotation[index];
  }

  List<Map<String, String>> _getFastFoodMenu() {
    final campus = _campuses[_selectedCampusIndex];
    return _fastFoodMenus[campus] ?? [];
  }

  String _timeLabel() {
    switch (_selectedTab) {
      case "Kahvaltı":
        return "08:00 - 10:30";
      case "Günün Menüsü":
        return "12:00 - 17:00";
      case "Fast Food":
        return "10:00 - 18:00";
      default:
        return "";
    }
  }

  String _priceLabel() {
    switch (_selectedTab) {
      case "Kahvaltı":
        return "₺25";
      case "Günün Menüsü":
        return "₺35";
      case "Fast Food":
        return "₺45+";
      default:
        return "";
    }
  }

  void _changeWeek(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays(_selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final dividerColor = Theme.of(context).dividerColor;
    final cardColor = Theme.of(context).cardColor;
    final weekendNoService =
        _isWeekend(_selectedDate) && _selectedTab != "Fast Food";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yemekhane Menüsü"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopInfoCard(context),
            const SizedBox(height: 16),
            _buildCampusSelector(context, textColor, dividerColor),
            const SizedBox(height: 16),
            _buildDateSelector(
              context,
              weekDays,
              textColor,
              mutedColor,
              dividerColor,
            ),
            const SizedBox(height: 16),
            _buildTabSelector(context, textColor, dividerColor, cardColor),
            const SizedBox(height: 16),
            _buildMenuCard(
              context: context,
              weekendNoService: weekendNoService,
              textColor: textColor,
              mutedColor: mutedColor,
              dividerColor: dividerColor,
              cardColor: cardColor,
            ),
            const SizedBox(height: 14),
            Text(
              "Menüler bilgilendirme amaçlıdır. Gün içinde değişiklik olabilir.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: mutedColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoCard(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.restaurant_menu, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Kampüs Yemek Bilgisi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Kampüs seç, günü belirle ve günün menüsünü ya da fast food seçeneklerini incele.",
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedTab == "Fast Food"
                        ? "Fast Food menüsü her gün erişilebilir."
                        : "Hafta sonu kahvaltı ve günün menüsü servisi yoktur.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusSelector(
      BuildContext context,
      Color textColor,
      Color dividerColor,
      ) {
    return _sectionCard(
      context: context,
      title: "Yerleşke Seçimi",
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _campuses.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final selected = _selectedCampusIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCampusIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 124,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor
                      : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.04)
                      : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppTheme.primaryColor : dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_city,
                      color: selected ? Colors.white : AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: Text(
                          _campuses[index],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? Colors.white : textColor,
                            fontSize: 13,
                            fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateSelector(
      BuildContext context,
      List<DateTime> weekDays,
      Color textColor,
      Color mutedColor,
      Color dividerColor,
      ) {
    return _sectionCard(
      context: context,
      title: "Tarih",
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _smallArrow(Icons.chevron_left, () => _changeWeek(-7)),
          const SizedBox(width: 6),
          Text(
            "${_monthName(_selectedDate.month)} ${_selectedDate.year}",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          _smallArrow(Icons.chevron_right, () => _changeWeek(7)),
        ],
      ),
      child: SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: weekDays.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final day = weekDays[index];
            final selected = _sameDay(day, _selectedDate);
            final weekend = _isWeekend(day);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = day;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 68,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppTheme.primaryColor : dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weekdayShort(day.weekday),
                      style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? Colors.white70
                            : weekend
                            ? AppTheme.destructiveColor
                            : mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${day.day}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabSelector(
      BuildContext context,
      Color textColor,
      Color dividerColor,
      Color cardColor,
      ) {
    return Row(
      children: _tabs.map((tab) {
        final selected = _selectedTab == tab;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
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
                  textAlign: TextAlign.center,
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

  Widget _buildMenuCard({
    required BuildContext context,
    required bool weekendNoService,
    required Color textColor,
    required Color mutedColor,
    required Color dividerColor,
    required Color cardColor,
  }) {
    if (weekendNoService) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: dividerColor),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.no_meals_outlined,
              size: 42,
              color: AppTheme.destructiveColor,
            ),
            const SizedBox(height: 12),
            Text(
              "Hafta Sonu Servis Yok",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Cumartesi ve pazar günleri kahvaltı ve günün menüsü servisi bulunmuyor. Fast Food sekmesi kullanılabilir.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedColor,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedTab == "Fast Food") {
      final items = _getFastFoodMenu();

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
            _menuHeader(context),
            const SizedBox(height: 18),
            ...items.map(
                  (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.04)
                      : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: dividerColor.withOpacity(0.7)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fastfood,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item["name"]!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
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
                        item["price"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final items =
    _selectedTab == "Kahvaltı" ? _getBreakfastMenu() : _getDailyMenu();

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
          _menuHeader(context),
          const SizedBox(height: 18),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Container(
              margin: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : 10,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.04)
                    : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dividerColor.withOpacity(0.7)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _selectedTab == "Kahvaltı"
                          ? Icons.free_breakfast
                          : Icons.restaurant_menu,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _menuHeader(BuildContext context) {
    final mutedColor = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextMuted
        : AppTheme.textMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _timeLabel(),
          style: TextStyle(
            color: mutedColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.successColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _priceLabel(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final dividerColor = Theme.of(context).dividerColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _smallArrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}