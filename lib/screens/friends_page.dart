import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crazy_dorm/services/friend_service.dart';
import 'friend_profile_page.dart';
import 'friend_qr_page.dart'; 

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    final friendService = FriendService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login'); 
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FriendScannerPage()),
          );
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final userDoc = docs[index];
              final userId = userDoc.id;

              if (userId == currentUser?.uid) return const SizedBox.shrink();

              final data = userDoc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'No Name';
              final email = data['email'] ?? '';
              final photoURL = data['photoURL'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                  child: photoURL.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '😊',
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                title: Text(name),
                subtitle: Text(email),
                trailing: ElevatedButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    try {
                      await friendService.addFriendById(userId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request sent!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FriendProfilePage(
                        userId: userId,
                        name: name,
                        email: email,
                        photoURL: photoURL,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
