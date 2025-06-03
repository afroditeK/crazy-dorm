import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendScannerPage extends StatelessWidget {
  const FriendScannerPage({super.key});

  Future<void> _addFriend(String friendId, BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || friendId == currentUser.uid) return;

    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final friendRef = FirebaseFirestore.instance.collection('users').doc(friendId);

    await currentUserRef.collection('friends').doc(friendId).set({'addedAt': FieldValue.serverTimestamp()});
    await friendRef.collection('friends').doc(currentUser.uid).set({'addedAt': FieldValue.serverTimestamp()});

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend added!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          final barcode = barcodeCapture.barcodes.first;
          final String? code = barcode.rawValue;
          if (code != null) {
            _addFriend(code, context);
          }
        },
      ),
    );
  }
}
