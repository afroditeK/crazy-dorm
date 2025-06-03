import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final String userId;
  final CollectionReference eventsCollection =
      FirebaseFirestore.instance.collection('events');

  EventService(this.userId);

  Stream<List<Event>> eventStream() {
    return eventsCollection
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  Future<void> addEvent(Event event) async {
    await eventsCollection.add(event.toMap());
  }

  Future<void> updateEvent(Event event) async {
    if (event.id == null) {
      throw Exception('Event id is null, cannot update');
    }
    await eventsCollection.doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String id) async {
    await eventsCollection.doc(id).delete();
  }

  Future<void> updateRSVP(String eventId, bool going) async {
    final docRef = eventsCollection.doc(eventId);
    await docRef.set({
      'rsvps': {userId: going}
    }, SetOptions(merge: true));  // merge true to not overwrite entire rsvps map
  }
}
