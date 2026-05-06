// Bu iki metodu lib/data/data_service.dart içinde
// class DataService { ... } kapanmadan hemen önce ekleyebilirsin.
// Eğer full data_service.dart dosyasını değiştirmek istemiyorsan sadece bunu kullan.

static const List<String> defaultPriceCategories = [
  "İçecekler",
  "Kahve Çeşitleri",
  "Tost Çeşitleri",
  "Atıştırmalıklar",
];

static Future<List<String>> fetchPriceCategories({bool forceRefresh = false}) async {
final categoryDocs = await fetchCollection(
'priceCategories',
forceRefresh: forceRefresh,
);

final categories = <String>[];

void addCategory(String? value) {
final category = value?.trim();
if (category == null || category.isEmpty) return;
if (!categories.contains(category)) {
categories.add(category);
}
}

for (final category in defaultPriceCategories) {
addCategory(category);
}

for (final doc in categoryDocs) {
addCategory(
doc['name']?.toString() ??
doc['title']?.toString() ??
doc['category']?.toString(),
);
}

return categories;
}

static Future<void> addPriceCategory(String categoryName) async {
final normalizedName = categoryName.trim();
if (normalizedName.isEmpty) return;

final docId = normalizedName
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9ğüşöçıİĞÜŞÖÇ]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

final safeDocId = docId.isEmpty
? DateTime.now().millisecondsSinceEpoch.toString()
    : docId;

await _db.collection('priceCategories').doc(safeDocId).set({
'id': safeDocId,
'name': normalizedName,
'createdAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

clearCollectionCache('priceCategories');
}
