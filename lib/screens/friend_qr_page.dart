import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendScannerPage extends StatefulWidget {
  const FriendScannerPage({super.key});

  @override
  State<FriendScannerPage> createState() => _FriendScannerPageState();
}

class _FriendScannerPageState extends State<FriendScannerPage> {
  bool _isProcessing = false; // Prevent multiple requests on fast scans

  Future<void> _sendFriendRequest(String friendId) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (friendId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't add yourself as a friend!")),
      );
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final friendRef = FirebaseFirestore.instance.collection('users').doc(friendId);

    try {
      // Check if friendId user exists
      final friendDoc = await friendRef.get();
      if (!friendDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found.')),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Update requests
      await currentUserRef.update({
        'friendRequestsSent': FieldValue.arrayUnion([friendId]),
      });

      await friendRef.update({
        'friendRequestsReceived': FieldValue.arrayUnion([currentUser.uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending friend request: $e')),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Friend's QR Code")),
      body: Stack(
        children: [
          MobileScanner(
            //todo: don't allow duplicates
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
