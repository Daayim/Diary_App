// lib/model/diary_entry_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  final String entryId;
  final DateTime date;
  final String description;
  final int rating;
  final List<String> imageUrls;

  DiaryEntry(
      {required this.entryId,
      required this.date,
      required this.description,
      required this.rating,
      this.imageUrls = const []});

  Map<String, dynamic> toFirestoreMap() {
    return {
      'entryId': entryId,
      'date': Timestamp.fromDate(date),
      'description': description,
      'rating': rating,
      'imageUrls': imageUrls,
    };
  }

  static DiaryEntry fromFirestoreMap(Map<String, dynamic> map) {
    return DiaryEntry(
      entryId: map['entryId'],
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'],
      rating: map['rating'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }
}
