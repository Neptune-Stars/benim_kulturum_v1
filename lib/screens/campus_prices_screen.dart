import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/filter_chip_widget.dart';

class CampusPricesScreen extends StatefulWidget {
  const CampusPricesScreen({Key? key}) : super(key: key);

  @override
  State<CampusPricesScreen> createState() => _CampusPricesScreenState();
}

class _CampusPricesScreenState extends State<CampusPricesScreen> {
  String? _selectedCategory;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _readCategory(Map<String, dynamic> data) {
    final value = data['category']?.toString().trim();
    if (value == null || value.isEmpty) return 'Other';
    return value;
  }

  String _readPrice(Map<String, dynamic> data) {
    final value = data['price']?.toString().trim();
    if (value == null || value.isEmpty) return '-';
    return value;
  }

  String _readName(Map<String, dynamic> data) {
    final value = data['name']?.toString().trim();
    if (value == null || value.isEmpty) return 'Unnamed Product';
    return value;
  }

  List<String> _buildCategories({
    required List<Map<String, dynamic>> priceCategoryDocs,
    required List<Map<String, dynamic>> priceItems,
  }) {
    final categories = <String>[];

    void addCategory(String? rawValue) {
      final value = rawValue?.trim();
      if (value == null || value.isEmpty) return;
      if (!categories.contains(value)) {
        categories.add(value);
      }
    }

    for (final category in DataService.defaultPriceCategories) {
      addCategory(category);
    }

    for (final categoryDoc in priceCategoryDocs) {
      addCategory(
        categoryDoc['name']?.toString() ??
            categoryDoc['title']?.toString() ??
            categoryDoc['category']?.toString(),
      );
    }

    for (final item in priceItems) {
      addCategory(item['category']?.toString());
    }

    return categories;
  }

  List<Map<String, dynamic>> _sortPriceItems(List<Map<String, dynamic>> items) {
    final sorted = List<Map<String, dynamic>>.from(items);
    sorted.sort((a, b) {
      final categoryCompare = _readCategory(a).compareTo(_readCategory(b));
      if (categoryCompare != 0) return categoryCompare;
      return _readName(a).compareTo(_readName(b));
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final dividerColor = Theme.of(context).dividerColor;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Campus Prices', showBack: true),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('priceCategories').snapshots(),
        builder: (context, categorySnapshot) {
          if (categorySnapshot.hasError) {
            return Center(
              child: Text(
                'Price categories could not be loaded.',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final priceCategoryDocs = categorySnapshot.data?.docs
              .map((doc) => {
            ...doc.data(),
            'firestoreDocId': doc.id,
          })
              .toList() ??
              <Map<String, dynamic>>[];

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db.collection('prices').snapshots(),
            builder: (context, priceSnapshot) {
              if (priceSnapshot.connectionState == ConnectionState.waiting &&
                  !priceSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (priceSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Price data could not be loaded.',
                    style: TextStyle(color: textColor),
                  ),
                );
              }

              final allPrices = priceSnapshot.data?.docs
                  .map((doc) => {
                ...doc.data(),
                'firestoreDocId': doc.id,
              })
                  .toList() ??
                  <Map<String, dynamic>>[];

              final categories = _buildCategories(
                priceCategoryDocs: priceCategoryDocs,
                priceItems: allPrices,
              );

              if (categories.isEmpty) {
                return const Center(
                  child: Text(
                    'Price category data not found.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                );
              }

              final selectedCategory = categories.contains(_selectedCategory)
                  ? _selectedCategory!
                  : categories.first;

              final filteredItems = _sortPriceItems(
                allPrices
                    .where((item) => _readCategory(item) == selectedCategory)
                    .toList(),
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return AppFilterChip(
                            label: category,
                            active: selectedCategory == category,
                            onTap: () {
                              setState(() => _selectedCategory = category);
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
                        child: filteredItems.isEmpty
                            ? const Center(
                          child: Text(
                            'No products in this category.',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                            : ListView.separated(
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: dividerColor, height: 1),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _readName(item),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _readPrice(item),
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
