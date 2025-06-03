import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendProfilePage extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String photoURL;

  const FriendProfilePage({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.photoURL,
  });

  Future<void> _addFriend(String friendId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || friendId == currentUser.uid) return;

    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final friendRef = FirebaseFirestore.instance.collection('users').doc(friendId);

    // Add friend to current user
    await currentUserRef.collection('friends').doc(friendId).set({'addedAt': FieldValue.serverTimestamp()});
    // Optionally: Add current user to friend as well
    await friendRef.collection('friends').doc(currentUser.uid).set({'addedAt': FieldValue.serverTimestamp()});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
              child: photoURL.isEmpty
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '😊', style: const TextStyle(fontSize: 40))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(email, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (!snapshot.hasData || !snapshot.data!.exists) return const Text('No additional info.');

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final description = data['description'] ?? 'No description';
                final nationality = data['nationality'] ?? 'Not specified';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About:', style: Theme.of(context).textTheme.titleMedium),
                    Text(description),
                    const SizedBox(height: 16),
                    Text('Nationality:', style: Theme.of(context).textTheme.titleMedium),
                    Text(nationality),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            if (currentUser != null && userId == currentUser.uid)
              QrImageView(
                data: currentUser.uid,
                version: QrVersions.auto,
                size: 150.0,
              )
            else
              ElevatedButton(
                onPressed: () => _addFriend(userId),
                child: const Text("Add Friend"),
              ),
          ],
        ),
      ),
    );
  }
}
