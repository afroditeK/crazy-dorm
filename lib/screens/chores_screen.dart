import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'package:crazy_dorm/theme/app_theme.dart';

//todo add the name

class ChoresScreen extends StatefulWidget {
  final String currentUser;
  final Function(int)? onCountUpdated;
  final List<Map<String, String>> friends;

  const ChoresScreen({
    Key? key,
    required this.currentUser,
    required this.friends,
    this.onCountUpdated,
  }) : super(key: key);

  @override
  _ChoresScreenState createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  final TaskService taskService = TaskService();
  late List<String> users;
  late Map<String, String> nameMap; // Mapping real names to display names

  @override
  void initState() {
    super.initState();
    users = [widget.currentUser, ...widget.friends.map((f) => f['name']!)];
    nameMap = {
      widget.currentUser: 'Me',
      ...{for (var f in widget.friends) f['name']!: f['name']!}
    };
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    String assignedTo = widget.currentUser;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add New Task", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: assignedTo,
                  items: users.map((user) => DropdownMenuItem(
                    value: user,
                    child: Text(nameMap[user]!),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        assignedTo = val;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Assign To',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(selectedDate == null
                      ? 'Pick Due Date'
                      : 'Due: ${DateFormat.yMMMd().format(selectedDate!)}'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a title")),
                  );
                  return;
                }
                final newTask = Task(
                  id: '',
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  dueDate: selectedDate,
                  assignedTo: assignedTo,
                );
                taskService.addTask(newTask);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Task '${newTask.title}' added for ${nameMap[assignedTo]}"),
                    backgroundColor: Colors.green.shade600,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🧹 Chores"),
        centerTitle: true,
        actions: [
          StreamBuilder<List<Task>>(
            stream: taskService.getTasks(),
            builder: (context, snapshot) {
              int assignedCount = 0;
              if (snapshot.hasData) {
                assignedCount = snapshot.data!
                    .where((task) =>
                        task.assignedTo == widget.currentUser && !task.isCompleted)
                    .length;
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.task_alt_outlined, size: 28),
                    tooltip: "Your Assigned Tasks",
                    onPressed: () {},
                  ),
                  if (assignedCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          assignedCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: "Add New Task",
            onPressed: _showAddTaskDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: taskService.getTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error loading tasks: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.cleaning_services_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("No tasks available",
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              return Dismissible(
                key: Key(task.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? Colors.redAccent : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    task.isCompleted ? Icons.delete_forever : Icons.block,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (!task.isCompleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("You can only delete completed tasks."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return false;
                  }
                  return true;
                },
                onDismissed: (_) {
                  taskService.deleteTask(task.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Deleted task: ${task.title}"),
                      backgroundColor: Colors.red.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    leading: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        key: ValueKey<bool>(task.isCompleted),
                        color:
                            task.isCompleted ? Colors.green : Colors.grey.shade500,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey : Colors.black87,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description != null &&
                            task.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              task.description!,
                              style: TextStyle(
                                color:
                                    task.isCompleted ? Colors.grey : Colors.black54,
                              ),
                            ),
                          ),
                        if (task.dueDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Due: ${DateFormat.yMMMd().format(task.dueDate!)}",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: task.isCompleted
                                    ? Colors.grey
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "Assigned to: ${nameMap[task.assignedTo] ?? task.assignedTo}",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: task.isCompleted
                                  ? Colors.grey
                                  : Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Checkbox(
                      activeColor: Colors.deepPurple,
                      value: task.isCompleted,
                      onChanged: (val) {
                        taskService.toggleTaskCompletion(task);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val == true
                                ? "Marked '${task.title}' as completed"
                                : "Marked '${task.title}' as incomplete"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
