import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late EventService _eventService;
  final _searchController = TextEditingController();

  late String userId;
  String userName = 'Unknown';
  bool isLoadingUserName = true;

  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    _eventService = EventService(userId);
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['username'] ?? 'Unknown';
          isLoadingUserName = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingUserName = false;
      });
    }
  }

  void _filterEvents(String query) {
    setState(() {
      _filteredEvents = _allEvents
          .where((event) => event.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _showAddEditDialog({Event? eventToEdit}) async {
    final titleController = TextEditingController(text: eventToEdit?.title ?? '');
    final descriptionController = TextEditingController(text: eventToEdit?.description ?? '');
    DateTime? selectedDate = eventToEdit?.date;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        Future<void> _pickDate() async {
          final today = DateTime.now();
          final picked = await showDatePicker(
            context: ctx,
            initialDate: selectedDate ?? today,
            firstDate: today.subtract(const Duration(days: 365)),
            lastDate: today.add(const Duration(days: 365 * 5)),
          );
          if (picked != null) {
            setState(() {
              selectedDate = picked;
            });
          }
        }

        return AlertDialog(
          title: Text(eventToEdit == null ? 'Add Event' : 'Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'No date chosen'
                            : 'Date: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Pick Date'),
                    )
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                if (title.isEmpty || description.isEmpty || selectedDate == null || isLoadingUserName) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fill all fields and wait for user data.')),
                  );
                  return;
                }

                if (eventToEdit == null) {
                  // Add new event
                  final newEvent = Event(
                    title: title,
                    description: description,
                    date: selectedDate!,
                    creatorId: userId,
                    creatorName: userName,
                    rsvps: {},
                  );
                  await _eventService.addEvent(newEvent);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event added')),
                  );
                } else {
                  // Update existing event
                  final updatedEvent = eventToEdit.copyWith(
                    title: title,
                    description: description,
                    date: selectedDate!,
                  );
                  await _eventService.updateEvent(updatedEvent);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event updated')),
                  );
                }

                Navigator.of(ctx).pop();
              },
              child: Text(eventToEdit == null ? 'Add' : 'Save'),
            )
          ],
        );
      }),
    );
  }

  void _deleteEvent(String id) async {
    await _eventService.deleteEvent(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event deleted')),
    );
  }

  void _updateRSVP(String eventId, bool going) async {
    await _eventService.updateRSVP(eventId, going);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _filterEvents,
                  decoration: InputDecoration(
                    labelText: 'Search Events',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Event', style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: _eventService.eventStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                _allEvents = snapshot.data ?? [];
                _filteredEvents = _searchController.text.isEmpty
                    ? _allEvents
                    : _allEvents
                        .where((e) => e.title.toLowerCase().contains(_searchController.text.toLowerCase()))
                        .toList();

                if (_filteredEvents.isEmpty) {
                  return const Center(child: Text('No events found'));
                }

                return ListView.builder(
                  itemCount: _filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = _filteredEvents[index];
                    final userRsvp = event.rsvps[userId];
                    final yesCount = event.rsvps.values.where((r) => r == true).length;
                    final noCount = event.rsvps.values.where((r) => r == false).length;

                    return Dismissible(
                      key: Key(event.id ?? event.title + index.toString()),
                      direction: event.creatorId == userId
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteEvent(event.id!),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        child: ListTile(
                          onTap: event.creatorId == userId
                              ? () => _showAddEditDialog(eventToEdit: event)
                              : null,
                          title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${event.description}\nDate: ${event.date.toLocal().toString().split(' ')[0]}'),
                              Text('Planned by: ${event.creatorName}',
                                  style: const TextStyle(fontStyle: FontStyle.italic)),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Text('RSVP: '),
                                  ChoiceChip(
                                    label: const Text('Yes'),
                                    selected: userRsvp == true,
                                    onSelected: (val) => _updateRSVP(event.id!, true),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('No'),
                                    selected: userRsvp == false,
                                    onSelected: (val) => _updateRSVP(event.id!, false),
                                  ),
                                  const SizedBox(width: 16),
                                  Text('Yes: $yesCount'),
                                  const SizedBox(width: 8),
                                  Text('No: $noCount'),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
