import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crazy_dorm/models/user_model.dart';

class FriendScannerPage extends StatefulWidget {
  const FriendScannerPage({super.key});

  @override
  State<FriendScannerPage> createState() => _FriendScannerPageState();
}

Future<List<UserModel>> fetchCurrentUserFriends(String currentUserId) async {
  final friendsSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('friends')
      .get();

  List<UserModel> friends = [];

  for (var doc in friendsSnapshot.docs) {
    String friendId = doc.id;
    final friendDoc = await FirebaseFirestore.instance.collection('users').doc(friendId).get();
    if (friendDoc.exists) {
      final dataWithUid = Map<String, dynamic>.from(friendDoc.data()!);
      dataWithUid['uid'] = friendId; 
      friends.add(UserModel.fromMap(dataWithUid));
    }
  }

  return friends;
}

class _FriendScannerPageState extends State<FriendScannerPage> {
  bool _isProcessing = false;

  Future<void> _sendFriendRequest(String friendId) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (friendId == currentUser.uid) {
      _showMessage("You can't add yourself as a friend!");
      _endProcessing();
      return;
    }

    // Re-fetch friend list to get most updated data
    final currentFriends = await fetchCurrentUserFriends(currentUser.uid);
    if (currentFriends.any((friend) => friend.uid == friendId)) {
      _showMessage("This user is already your friend!");
      _endProcessing();
      return;
    }

    // Check if friend request already sent
    final currentUserDoc =
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final sentRequests = List<String>.from(
        currentUserDoc.data()?['friendRequestsSent'] ?? []);
    if (sentRequests.contains(friendId)) {
      _showMessage("Friend request already sent!");
      _endProcessing();
      return;
    }

    // Check if friend exists
    final friendRef =
        FirebaseFirestore.instance.collection('users').doc(friendId);
    final friendDoc = await friendRef.get();

    if (!friendDoc.exists) {
      _showMessage("User not found.");
      _endProcessing();
      return;
    }

    try {
      // Send friend request
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'friendRequestsSent': FieldValue.arrayUnion([friendId]),
      });

      await friendRef.update({
        'friendRequestsReceived': FieldValue.arrayUnion([currentUser.uid]),
      });

      _showMessage("Friend request sent!");
      Navigator.pop(context); // Close scanner after sending
    } catch (e) {
      _showMessage("Error sending friend request: $e");
      _endProcessing();
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _endProcessing() {
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Friend's QR Code")),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_isProcessing) return;

              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue;
                if (code != null && code.isNotEmpty) {
                  print("Scanned code: $code");
                  _sendFriendRequest(code);
                }
              }
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black54,
                child: const Text(
                  'Point your camera at a friend\'s QR code',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
