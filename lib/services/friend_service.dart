// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class FriendService {
//   static final _auth = FirebaseAuth.instance;
//   static final _firestore = FirebaseFirestore.instance;

//   static Future<void> sendFriendRequest(String toUserId) async {
//     final fromUserId = _auth.currentUser!.uid;

//     await _firestore
//         .collection('users')
//         .doc(toUserId)
//         .collection('friendRequests')
//         .doc(fromUserId)
//         .set({
//       'fromUserId': fromUserId,
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//   }

//   static Future<void> acceptFriendRequest(String fromUserId) async {
//     final currentUserId = _auth.currentUser!.uid;

//     await _firestore
//         .collection('users')
//         .doc(currentUserId)
//         .collection('friends')
//         .doc(fromUserId)
//         .set({'uid': fromUserId});

//     await _firestore
//         .collection('users')
//         .doc(fromUserId)
//         .collection('friends')
//         .doc(currentUserId)
//         .set({'uid': currentUserId});

//     await _firestore
//         .collection('users')
//         .doc(currentUserId)
//         .collection('friendRequests')
//         .doc(fromUserId)
//         .delete();
//   }

//   static Future<void> rejectFriendRequest(String fromUserId) async {
//     final currentUserId = _auth.currentUser!.uid;
//     await _firestore
//         .collection('users')
//         .doc(currentUserId)
//         .collection('friendRequests')
//         .doc(fromUserId)
//         .delete();
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sends a friend request by adding the target userId to current user's 'friendRequestsSent'
  // and adding the current user to the target user's 'friendRequestsReceived'
  Future<void> addFriendById(String friendUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No logged in user');
    }

    final currentUserId = currentUser.uid;

    final batch = _firestore.batch();

    // Add friendUserId to current user's sent requests
    final sentRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friendRequestsSent')
        .doc(friendUserId);
    batch.set(sentRef, {'timestamp': FieldValue.serverTimestamp()});

    // Add currentUserId to friend's received requests
    final receivedRef = _firestore
        .collection('users')
        .doc(friendUserId)
        .collection('friendRequestsReceived')
        .doc(currentUserId);
    batch.set(receivedRef, {'timestamp': FieldValue.serverTimestamp()});

    await batch.commit();
  }
}
