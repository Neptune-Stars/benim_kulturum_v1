import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final int id;
  final String title;
  final String content;
  final String date;
  final String category;
  final bool isNew;
  final String publishDate;
  final String publishTime;
  final Timestamp? publishAt;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.category,
    required this.isNew,
    required this.publishDate,
    required this.publishTime,
    this.publishAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Announcement.fromMap(Map<dynamic, dynamic> data) {
    final map = Map<String, dynamic>.from(data);

    return Announcement(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      category: map['category']?.toString() ?? 'general',
      isNew: map['isNew'] == true,
      publishDate: map['publishDate']?.toString() ?? '',
      publishTime: map['publishTime']?.toString() ?? '',
      publishAt: map['publishAt'] is Timestamp ? map['publishAt'] : null,
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] : null,
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'category': category,
      'isNew': isNew,
      'publishDate': publishDate,
      'publishTime': publishTime,
      'publishAt': publishAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}