class Event {
  final int id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String description;
  final String category;

  Event({required this.id, required this.title, required this.date, required this.time, required this.location, required this.description, required this.category});

factory Event.fromMap(Map<dynamic, dynamic> data) {
// Hive'dan gelen dynamic map'i String key'li Map'e dönüştürüyoruz
final Map<String, dynamic> map = Map<String, dynamic>.from(data);

return Event(
id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
title: map['title'] ?? '',
date: map['date'] ?? '',
time: map['time'] ?? '',
location: map['location'] ?? '',
description: map['description'] ?? '',
category: map['category'] ?? '',
);
}
// ------------------------------------------
}