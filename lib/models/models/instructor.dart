class Instructor {
  final int id;
  final String name;
  final String department;
  final String office;
  final String title;
  final String filter;
  final String email;
  final String? imageUrl; // Yeni: Fotoğraf yolu için eklendi

  Instructor({
    required this.id,
    required this.name,
    required this.department,
    required this.office,
    required this.title,
    required this.filter,
    required this.email,
    this.imageUrl, // Yeni: Fotoğraf yolu opsiyonel olarak eklendi
  });

  // Veritabanından gelen veriyi güvenli şekilde karşılayan metod
  factory Instructor.fromMap(Map<dynamic, dynamic> data) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);

    return Instructor(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      office: map['office'] ?? '',
      title: map['title'] ?? '',
      filter: map['filter'] ?? '',
      email: map['email'] ?? '',
      imageUrl: map['imageUrl'], // JSON/Hive'daki imageUrl alanını okur
    );
  }
}