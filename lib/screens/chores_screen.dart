// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChoresScreen extends StatefulWidget {
  final String userEmail;
  final List<String> friendsEmails;

  const ChoresScreen({
    super.key,
    required this.userEmail,
    required this.friendsEmails,
  });

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  final TextEditingController _taskController = TextEditingController();
  String? _selectedAssignee;
  String? _editingTaskId;

  final List<String> _predefinedChores = [
    'Wash dishes',
    'Clean bathroom',
    'Vacuum floor',
    'Take out trash',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAssignee = widget.userEmail;
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateTask() async {
    final taskText = _taskController.text.trim();
    if (taskText.isEmpty || _selectedAssignee == null) return;

    final choresRef = FirebaseFirestore.instance.collection('chores');

    try {
      if (_editingTaskId == null) {
        await choresRef.add({
          'text': taskText,
          'assignedTo': _selectedAssignee,
          'doneBy': [],
          'createdAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added!')),
        );
      } else {
        await choresRef.doc(_editingTaskId).update({
          'text': taskText,
          'assignedTo': _selectedAssignee,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated!')),
        );
        _editingTaskId = null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    _taskController.clear();
    setState(() {
      _selectedAssignee = widget.userEmail;
      _editingTaskId = null;
    });
  }

  Future<void> _toggleDone(DocumentSnapshot taskDoc, bool isDoneNow) async {
    final taskRef = FirebaseFirestore.instance.collection('chores').doc(taskDoc.id);
    final List<dynamic> doneBy = List.from(taskDoc['doneBy'] ?? []);
    final user = widget.userEmail;
    final task = taskDoc.data() as Map<String, dynamic>;
    final assignedTo = task['assignedTo'] as String? ?? '';

    if (assignedTo != user) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only mark as done/undone your own tasks.')),
      );
      return;
    }

    if (isDoneNow) {
      if (!doneBy.contains(user)) {
        doneBy.add(user);
      }
    } else {
      doneBy.remove(user);
    }

    await taskRef.update({'doneBy': doneBy});
    setState(() {});
  }

  Future<void> _deleteTask(DocumentSnapshot taskDoc) async {
  try {
    await FirebaseFirestore.instance.collection('chores').doc(taskDoc.id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted!')),
    );

    // Clear editing input and assignee after deleting
    _taskController.clear();
    setState(() {
      _selectedAssignee = widget.userEmail;
      _editingTaskId = null;
    });

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error deleting task: $e')),
    );
  }
}

  Future<void> _confirmDeleteTask(DocumentSnapshot taskDoc) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Task'),
      content: const Text('Are you sure you want to delete this task?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await _deleteTask(taskDoc);
  }
}


  Widget _buildTaskItem(DocumentSnapshot taskDoc) {
    final task = taskDoc.data() as Map<String, dynamic>;
    final assignedTo = task['assignedTo'] as String? ?? '';
    final doneBy = List<String>.from(task['doneBy'] ?? []);
    final isDone = doneBy.contains(widget.userEmail);
    final createdAt = task['createdAt'] as Timestamp?;
    final createdDate = createdAt?.toDate();

    final assignableUsers = [widget.userEmail, ...widget.friendsEmails].toSet().toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Checkbox(
          value: isDone,
          onChanged: (val) {
            if (val != null) _toggleDone(taskDoc, val);
          },
        ),
        title: Text(
          task['text'] ?? '',
          style: TextStyle(
            decoration: isDone ? TextDecoration.lineThrough : null,
            fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          'Assigned to: ${assignedTo.split('@')[0]}'
          '${createdDate != null ? ' • ${DateFormat('dd/MM/yyyy').format(createdDate)}' : ''}',
          style: TextStyle(color: Colors.grey[700]),
        ),
        trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () => _confirmDeleteTask(taskDoc),
        tooltip: 'Delete task',
        ),
        onTap: () {
          setState(() {
            _editingTaskId = taskDoc.id;
            _taskController.text = task['text'] ?? '';
            if (assignableUsers.contains(assignedTo)) {
              _selectedAssignee = assignedTo;
            } else {
              _selectedAssignee = widget.userEmail;
            }
          });
        },
      ),
    );
  }

  Widget _buildPredefinedChores() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _predefinedChores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (_, i) {
          final chore = _predefinedChores[i];
          return ActionChip(
            label: Text(chore, style: const TextStyle(fontSize: 14)),
            onPressed: () {
              setState(() {
                _taskController.text = chore;
              });
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _taskStream() {
    return FirebaseFirestore.instance
        .collection('chores')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final assignableUsers = [widget.userEmail, ...widget.friendsEmails].toSet().toList();

    final isAddUpdateEnabled =
        _taskController.text.trim().isNotEmpty && _selectedAssignee != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chores'),
      ),
      body: Column(
        children: [
          _buildPredefinedChores(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                labelText: 'New chore',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (isAddUpdateEnabled) _addOrUpdateTask();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAssignee,
                    decoration: const InputDecoration(labelText: 'Assign to'),
                    items: assignableUsers.map((email) {
                      return DropdownMenuItem<String>(
                        value: email,
                        child: Text(email.split('@')[0]),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAssignee = val),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isAddUpdateEnabled ? _addOrUpdateTask : null,
                  child: Text(_editingTaskId == null ? 'Add' : 'Update'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: StreamBuilder<QuerySnapshot>(
              stream: _taskStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!.docs;

                final userTasksCount = tasks
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['assignedTo'] == widget.userEmail;
                    })
                    .length;

                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'You have $userTasksCount chores assigned',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _taskStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!.docs;

                if (tasks.isEmpty) {
                  return const Center(child: Text('No chores yet.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => _buildTaskItem(tasks[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
