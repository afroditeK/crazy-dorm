import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crazy_dorm/models/user_model.dart';
import 'location_picker_page.dart';

class FriendProfilePage extends StatefulWidget {
  final String userId;

  const FriendProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  UserModel? _user;
  bool _isLoading = true;

  final List<Map<String, String>> _countries = [
    {'name': 'Greece', 'flag': '🇬🇷'},
    {'name': 'Slovenia', 'flag': '🇸🇮'},
    {'name': 'Italy', 'flag': '🇮🇹'},
    {'name': 'France', 'flag': '🇫🇷'},
    {'name': 'Germany', 'flag': '🇩🇪'},
    {'name': 'Spain', 'flag': '🇪🇸'},
    {'name': 'Portugal', 'flag': '🇵🇹'},
    {'name': 'Netherlands', 'flag': '🇳🇱'},
    {'name': 'Poland', 'flag': '🇵🇱'},
    {'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'name': 'United States', 'flag': '🇺🇸'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _user = UserModel.fromMap(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getNationalityFlag(String? nationality) {
    final country = _countries.firstWhere(
      (c) => c['name'] == nationality,
      orElse: () => {'flag': '👤'},
    );
    return country['flag'] ?? '👤';
  }

  Widget _infoTile(IconData icon, String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple.shade700, size: 28),
          const SizedBox(width: 18),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.deepPurple.shade900,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.shade800,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatar = _user?.emojiAvatar;
    final flag = _getNationalityFlag(_user?.nationality);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: CircleAvatar(
        radius: 80,
        backgroundColor: Colors.white,
        child: Text(
          avatar?.isNotEmpty == true ? avatar! : flag,
          style: const TextStyle(fontSize: 72),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(child: Text('User not found', style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Text('${_user!.name}\'s Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 28),
              Text(
                _user!.name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  letterSpacing: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _user!.description ?? 'No description provided.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.deepPurple.shade700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 36),

              // Info tiles
              _infoTile(Icons.home, 'Room', _user!.room),
              _infoTile(Icons.phone, 'Phone', _user!.phone),
              _infoTile(Icons.school, 'Faculty', _user!.faculty),
              _infoTile(Icons.flag, 'Nationality', _user!.nationality),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New feature coming soon!')),
          );
        },
        label: const Text('New feature'),
        icon: const Icon(Icons.map),
        backgroundColor: Colors.deepPurple.shade50,
      ),
    );
  }
}
