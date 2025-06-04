import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendFriendRequest(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No logged in user');

    final currentUserId = currentUser.uid;
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final targetUserRef = _firestore.collection('users').doc(targetUserId);

    final batch = _firestore.batch();

    // Add targetUserId to currentUser's sent requests
    batch.update(currentUserRef, {
      'friendRequestsSent': FieldValue.arrayUnion([targetUserId]),
    });

    // Add currentUserId to targetUser's received requests
    batch.update(targetUserRef, {
      'friendRequestsReceived': FieldValue.arrayUnion([currentUserId]),
    });

    await batch.commit();
  }

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

    // Remove currentUserId from requester's friendRequestsSent
    // and add currentUserId to their friends list
    batch.update(requesterRef, {
      'friendRequestsSent': FieldValue.arrayRemove([currentUserId]),
      'friends': FieldValue.arrayUnion([currentUserId]),
    });

    await batch.commit();
  }

  Future<void> rejectFriendRequest(String requesterId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No logged in user');

    final currentUserId = currentUser.uid;
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final requesterRef = _firestore.collection('users').doc(requesterId);

    final batch = _firestore.batch();

    // Remove the request from both users
    batch.update(currentUserRef, {
      'friendRequestsReceived': FieldValue.arrayRemove([requesterId]),
    });

    batch.update(requesterRef, {
      'friendRequestsSent': FieldValue.arrayRemove([currentUserId]),
    });

    await batch.commit();
  }
}