import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> acceptFriendRequest(String requesterId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No logged in user');

    final currentUserId = currentUser.uid;

    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final requesterRef = _firestore.collection('users').doc(requesterId);

    final batch = _firestore.batch();

    // Remove requesterId from currentUser's friendRequestsReceived
    batch.update(currentUserRef, {
      'friendRequestsReceived': FieldValue.arrayRemove([requesterId]),
      'friends': FieldValue.arrayUnion([requesterId]),
    });

    // Add currentUserId to requester's friends list
    batch.update(requesterRef, {
      'friends': FieldValue.arrayUnion([currentUserId]),
    });

    await batch.commit();
  }

  Future<void> rejectFriendRequest(String requesterId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No logged in user');

    final currentUserId = currentUser.uid;
    final currentUserRef = _firestore.collection('users').doc(currentUserId);

    // Just remove the friend request without adding friend
    await currentUserRef.update({
      'friendRequestsReceived': FieldValue.arrayRemove([requesterId]),
    });
  }
}
