import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;

import 'chores_screen.dart';
import 'events_screen.dart';
import 'profile_page.dart';
import 'friends_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isTablet = false;

  String? userId;
  String? username;
  final ValueNotifier<int> _choreCountNotifier = ValueNotifier<int>(0);
  List<Map<String, String>> friends = [];

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
      username = currentUser.displayName ?? 'Anonymous';
      loadFriends();
    }
  }

  Future<void> loadFriends() async {
    if (userId != null) {
      final loadedFriends = await getFriendsList(userId!);
      setState(() {
        friends = loadedFriends;
      });
    }
  }

  Future<List<Map<String, String>>> getFriendsList(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null && data['friends'] != null) {
        List<String> friendIds = List<String>.from(data['friends']);
        List<Map<String, String>> friendDetails = [];

        for (String friendId in friendIds) {
          final friendDoc = await FirebaseFirestore.instance.collection('users').doc(friendId).get();
          if (friendDoc.exists) {
            final friendData = friendDoc.data();
            if (friendData != null) {
              final displayName = friendData['displayName'] ?? 'Unknown';
              friendDetails.add({'uid': friendId, 'name': displayName});
            }
          }
        }

        return friendDetails;
      }
    }

    return [];
  }

  @override
  void dispose() {
    _choreCountNotifier.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> _getPages() {
    if (userId == null || username == null) {
      return [const Center(child: CircularProgressIndicator())];
    }

    return [
      ChoresScreen(
        currentUser: username!,
        friends: friends, 
        onCountUpdated: (int count) {
          _choreCountNotifier.value = count;
        },
      ),
      EventsPage(),
      const FriendsPage(),
      ProfilePage(userId: userId!, isSelf: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: Row(
        children: [
          if (_isTablet)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabTapped,
              labelType: NavigationRailLabelType.selected,
              destinations: [
                NavigationRailDestination(
                  icon: ValueListenableBuilder<int>(
                    valueListenable: _choreCountNotifier,
                    builder: (context, count, _) => badges.Badge(
                      showBadge: count > 0,
                      badgeContent: Text('$count'),
                      child: const Icon(Icons.cleaning_services),
                    ),
                  ),
                  label: const Text('Chores'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.event),
                  label: Text('Events'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Friends'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _getPages()[_currentIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isTablet
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              items: [
                BottomNavigationBarItem(
                  icon: ValueListenableBuilder<int>(
                    valueListenable: _choreCountNotifier,
                    builder: (context, count, _) => badges.Badge(
                      showBadge: count > 0,
                      badgeContent: Text('$count'),
                      child: const Icon(Icons.cleaning_services),
                    ),
                  ),
                  label: 'Chores',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.event),
                  label: 'Events',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Friends',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
