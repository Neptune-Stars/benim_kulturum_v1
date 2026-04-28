class Building {
  final int id;
  final String name;
  final String abbr;
  final int floors;
  final int rooms;
  final String type;
  final String location;

  Building({
    required this.id,
    required this.name,
    required this.abbr,
    required this.floors,
    required this.rooms,
    required this.type,
    required this.location,
  });

  factory Building.fromMap(Map<dynamic, dynamic> data) {
    final map = Map<String, dynamic>.from(data);

    return Building(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      name: map['name']?.toString() ?? '',
      abbr: map['abbr']?.toString() ?? '',
      floors: map['floors'] is int
          ? map['floors']
          : int.tryParse(map['floors'].toString()) ?? 0,
      rooms: map['rooms'] is int
          ? map['rooms']
          : int.tryParse(map['rooms'].toString()) ?? 0,
      type: map['type']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'abbr': abbr,
      'floors': floors,
      'rooms': rooms,
      'type': type,
      'location': location,
    };
  }
}