import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String? id;
  final String title;
  final String description;
  final DateTime date;
  final String creatorId;
  final String creatorName;
  final Map<String, bool> rsvps;

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.creatorId,
    required this.creatorName,
    required this.rsvps,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? 'Unknown',
      rsvps: (data['rsvps'] != null) 
          ? Map<String, bool>.from(data['rsvps'] as Map) 
          : <String, bool>{},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'creatorId': creatorId,
      'creatorName': creatorName,
      'rsvps': rsvps,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? creatorId,
    String? creatorName,
    Map<String, bool>? rsvps,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      rsvps: rsvps ?? this.rsvps,
    );
  }
}
