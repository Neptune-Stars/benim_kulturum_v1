class Instructor {
  final int id;
  final String name;
  final String department;
  final String office;
  final String title;
  final String filter;
  final String email;
  final String? imageUrl;

  Instructor({
    required this.id,
    required this.name,
    required this.department,
    required this.office,
    required this.title,
    required this.filter,
    required this.email,
    this.imageUrl,
  });

  factory Instructor.fromMap(Map<dynamic, dynamic> data) {
    final map = Map<String, dynamic>.from(data);

    return Instructor(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      name: map['name']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      office: map['office']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      filter: map['filter']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'office': office,
      'title': title,
      'filter': filter,
      'email': email,
      'imageUrl': imageUrl,
    };
  }
}