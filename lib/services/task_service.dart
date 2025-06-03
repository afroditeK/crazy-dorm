import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final CollectionReference _taskCollection =
      FirebaseFirestore.instance.collection('tasks');

  /// Stream of all tasks, ordered by due date ascending
  Stream<List<Task>> getTasks() {
    return _taskCollection
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromFirestore(doc);
      }).toList();
    });
  }

  /// Add a new task to Firestore
  Future<void> addTask(Task task) async {
    await _taskCollection.add(task.toFirestore());
  }

  /// Delete a task by ID
  Future<void> deleteTask(String taskId) async {
    await _taskCollection.doc(taskId).delete();
  }

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(Task task) async {
    await _taskCollection.doc(task.id).update({
      'isCompleted': !task.isCompleted,
    });
  }
}
