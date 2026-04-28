import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final int id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String description;
  final String category;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    required this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromMap(Map<dynamic, dynamic> data) {
    final map = Map<String, dynamic>.from(data);

    return Event(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Genel',
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] : null,
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'location': location,
      'description': description,
      'category': category,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}