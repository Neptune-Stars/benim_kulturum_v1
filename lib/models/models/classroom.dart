import 'package:cloud_firestore/cloud_firestore.dart';

class Classroom {
  final int id;
  final String name;
  final String building;
  final String campus;
  final String location;
  final int capacity;
  final String type;
  final int floor;
  final String floorLabel;
  final Timestamp? updatedAt;

  Classroom({
    required this.id,
    required this.name,
    required this.building,
    required this.campus,
    required this.location,
    required this.capacity,
    required this.type,
    required this.floor,
    required this.floorLabel,
    this.updatedAt,
  });

  factory Classroom.fromMap(Map<dynamic, dynamic> data) {
    final map = Map<String, dynamic>.from(data);

    return Classroom(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      name: map['name']?.toString() ?? '',
      building: map['building']?.toString() ?? '',
      campus: map['campus']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      capacity: map['capacity'] is int
          ? map['capacity']
          : int.tryParse(map['capacity'].toString()) ?? 0,
      type: map['type']?.toString() ?? '',
      floor: map['floor'] is int
          ? map['floor']
          : int.tryParse(map['floor'].toString()) ?? 0,
      floorLabel: map['floorLabel']?.toString() ?? '',
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'building': building,
      'campus': campus,
      'location': location,
      'capacity': capacity,
      'type': type,
      'floor': floor,
      'floorLabel': floorLabel,
      'updatedAt': updatedAt,
    };
  }
}