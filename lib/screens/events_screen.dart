// events_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';
import 'location_picker_page.dart';
import 'live_location_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  _EventsPageState createState() => _EventsPageState();
}

final List<String> mariborPlaces = [
  'Main Square (Glavni trg)',
  'Maribor Castle',
  'Pyramid Hill (Piramida)',
  'Maribor Cathedral',
  'City Park (Mestni park)',
  "Nana's Bistro & Kavarna"
];

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      userId = '';
    } else {
      userId = user.uid;
      _eventService = EventService(userId);
      _loadUserName();
    }

    _searchController.addListener(() {
      _filterEvents(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['username'] ?? 'Unknown';
          isLoadingUserName = false;
        });
      } else {
        setState(() {
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
      if (query.isEmpty) {
        _filteredEvents = List.from(_allEvents);
      } else {
        _filteredEvents = _allEvents
            .where((event) => event.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _showAddEditDialog({Event? eventToEdit}) async {
    final titleController = TextEditingController(text: eventToEdit?.title ?? '');
    final descriptionController = TextEditingController(text: eventToEdit?.description ?? '');
    String? selectedLocation = eventToEdit?.location.isNotEmpty == true ? eventToEdit!.location : null;
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
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Location'),
                  value: selectedLocation,
                  items: mariborPlaces
                      .map((place) => DropdownMenuItem(
                            value: place,
                            child: Text(place),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedLocation = val;
                    });
                  },
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
                final location = selectedLocation?.trim() ?? '';
                if (title.isEmpty || selectedDate == null || isLoadingUserName || location.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill the title, date and location fields.')),
                  );
                  return;
                }

                if (eventToEdit == null) {
                  final newEvent = Event(
                    title: title,
                    description: description,
                    location: location,
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
                  final updatedEvent = eventToEdit.copyWith(
                    title: title,
                    description: description,
                    location: location,
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

  Future<void> _deleteEvent(String id) async {
    await _eventService.deleteEvent(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event deleted')),
    );
  }

  Future<void> _updateRSVP(String eventId, bool going) async {
    final currentEvent = _allEvents.firstWhere((e) => e.id == eventId);
    final currentRsvp = currentEvent.rsvps[userId];

    if (currentRsvp == going) {
      await _eventService.updateRSVP(eventId, !going);
    } else {
      await _eventService.updateRSVP(eventId, going);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Events')),
        body: const Center(child: Text('Please log in to see events')),
      );
    }

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
                    ? List.from(_allEvents)
                    : _allEvents
                        .where((e) => e.title.toLowerCase().contains(_searchController.text.toLowerCase()))
                        .toList();

                if (_filteredEvents.isEmpty) {
                  return const Center(child: Text('No events found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _filteredEvents.length,
                  itemBuilder: (ctx, index) {
                    final event = _filteredEvents[index];
                    final rsvps = event.rsvps;
                    final goingCount = rsvps.values.where((v) => v == true).length;
                    final notGoingCount = rsvps.values.where((v) => v == false).length;
                    final userRsvp = rsvps[userId];

                    return Dismissible(
                      key: Key(event.id ?? index.toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Event'),
                            content: const Text('Are you sure you want to delete this event?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        return confirm == true;
                      },
                      onDismissed: (_) {
                        _deleteEvent(event.id ?? '');
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () => _showAddEditDialog(eventToEdit: event),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.title,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      event.date.toLocal().toString().split(' ')[0],
                                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(event.description, style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 18, color: Colors.deepPurple),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(event.location, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LocationPage(location: event.location),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.map_outlined),
                                      label: const Text('View Map', style: TextStyle(fontSize: 14.0)),
                                      style: ElevatedButton.styleFrom(minimumSize: const Size(110, 30)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: userRsvp == true ? Colors.green.shade600 : Colors.grey.shade300,
                                        foregroundColor: userRsvp == true ? Colors.white : Colors.black87,
                                      ),
                                      icon: const Icon(Icons.check),
                                      label: Text('Yes ($goingCount)', style: const TextStyle(fontSize: 14.0)),
                                      onPressed: () => _updateRSVP(event.id ?? '', true),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: userRsvp == false ? Colors.red.shade600 : Colors.grey.shade300,
                                        foregroundColor: userRsvp == false ? Colors.white : Colors.black87,
                                      ),
                                      icon: const Icon(Icons.close),
                                      label: Text('No ($notGoingCount)', style: const TextStyle(fontSize: 14.0)),
                                      onPressed: () => _updateRSVP(event.id ?? '', false),
                                    ),
                                    if (event.creatorId == userId)
                                      IconButton(
                                        tooltip: 'Edit Event',
                                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                        onPressed: () => _showAddEditDialog(eventToEdit: event),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        final selectedLocation = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LiveLocationPage()),
        );

        if (selectedLocation != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected location: $selectedLocation')),
          );
        }
      },
      label: const Text('Show Live Location'),
      icon: const Icon(Icons.map),
    ),
        );
  }

}
