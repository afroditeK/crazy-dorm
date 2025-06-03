import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String assignedTo;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.assignedTo,
    this.isCompleted = false,
  });

  // Factory to create a Task from Firestore document snapshot
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      dueDate:
          data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      assignedTo: data['assignedTo'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  // Convert Task to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
    };
  }
}
