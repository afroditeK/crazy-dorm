import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crazy_dorm/services/friend_service.dart';
import 'friend_profile_page.dart';
import 'friend_qr_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}


class _FriendsPageState extends State<FriendsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FriendService _friendService = FriendService();

  Future<Map<String, dynamic>?> _fetchUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('No user logged in'));
    }
    final currentUserId = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     onPressed: () async {
        //       await _auth.signOut();
        //       Navigator.of(context).pushReplacementNamed('/login');
        //     },
        //   ),
        // ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FriendScannerPage()),
          );
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final userDoc = snapshot.data!;
          final data = userDoc.data() as Map<String, dynamic>;

          final List<dynamic> friendsRaw = data['friends'] ?? [];
          final List<dynamic> requestsRaw = data['friendRequestsReceived'] ?? [];
          final List<dynamic> sentRequestsRaw = data['friendRequestsSent'] ?? [];

          final List<String> friendIds = List<String>.from(friendsRaw);
          final List<String> requestIds = List<String>.from(requestsRaw);
          final List<String> sentRequestIds = List<String>.from(sentRequestsRaw);

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (requestIds.isNotEmpty) ...[
                const ListTile(
                  title: Text('Friend Requests', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                for (final requesterId in requestIds)
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _fetchUser(requesterId),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox();
                      final user = userSnap.data!;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['photoURL'] != null && user['photoURL'].toString().isNotEmpty
                              ? NetworkImage(user['photoURL'])
                              : null,
                          child: (user['photoURL'] == null || user['photoURL'].toString().isEmpty)
                              ? Text((user['name'] ?? 'U').toString()[0].toUpperCase())
                              : null,
                        ),
                        title: Text(user['name'] ?? 'Unknown'),
                        subtitle: const Text('wants to be your friend'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await _friendService.acceptFriendRequest(requesterId);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Friend request accepted')),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                await _friendService.rejectFriendRequest(requesterId);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Friend request rejected')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const Divider(),
              ],
              const ListTile(
                title: Text('Your Friends', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (friendIds.isEmpty)
                const ListTile(title: Text('You have no friends yet.')),
              for (final friendId in friendIds)
                FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchUser(friendId),
                  builder: (context, friendSnap) {
                    if (!friendSnap.hasData) return const SizedBox();
                    final friend = friendSnap.data!;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: friend['photoURL'] != null && friend['photoURL'].toString().isNotEmpty
                            ? NetworkImage(friend['photoURL'])
                            : null,
                        child: (friend['photoURL'] == null || friend['photoURL'].toString().isEmpty)
                            ? Text((friend['name'] ?? 'U').toString()[0].toUpperCase())
                            : null,
                      ),
                      title: Text(friend['name'] ?? 'Unknown'),
                      subtitle: Text(friend['email'] ?? ''),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FriendProfilePage(
                              userId: friendId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              const Divider(),
              const ListTile(
                title: Text('Discover People', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, usersSnapshot) {
                  if (usersSnapshot.hasError) {
                    return const ListTile(title: Text('Error loading users.'));
                  }
                  if (!usersSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allUsers = usersSnapshot.data!.docs;
                  final discoverableUsers = allUsers.where((doc) {
                    final id = doc.id;
                    return id != currentUserId &&
                        !friendIds.contains(id) &&
                        !requestIds.contains(id) &&
                        !sentRequestIds.contains(id);
                  }).toList();

                  if (discoverableUsers.isEmpty) {
                    return const ListTile(title: Text('No new users to discover.'));
                  }

                  return Column(
                    children: discoverableUsers.map((userDoc) {
                      final user = userDoc.data() as Map<String, dynamic>;
                      final userId = userDoc.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['photoURL'] != null && user['photoURL'].toString().isNotEmpty
                              ? NetworkImage(user['photoURL'])
                              : null,
                          child: (user['photoURL'] == null || user['photoURL'].toString().isEmpty)
                              ? Text((user['name'] ?? 'U').toString()[0].toUpperCase())
                              : null,
                        ),
                        title: Text(user['name'] ?? 'Unknown'),
                        subtitle: Text(user['email'] ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            await _friendService.sendFriendRequest(userId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Friend request sent to ${user['name']}')),
                              );
                            }
                          },
                          child: const Text('Add Friend'),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
