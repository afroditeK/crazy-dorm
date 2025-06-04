import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crazy_dorm/models/user_model.dart';
// import 'location_picker_page.dart';
import 'package:crazy_dorm/theme/app_colors.dart';
import 'package:crazy_dorm/theme/app_text_styles.dart';

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 18),
          Text(
            '$label:',
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
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
          colors: [AppColors.primary.withOpacity(0.7), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
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
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: Center(
          child: Text('User not found', style: theme.textTheme.bodyLarge),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
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
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _user!.description ?? 'No description provided.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(height: 1.3),
              ),
              const SizedBox(height: 36),
              _infoTile(Icons.home, 'Room', _user!.room),
              _infoTile(Icons.phone, 'Phone', _user!.phone),
              _infoTile(Icons.school, 'Faculty', _user!.faculty),
              _infoTile(Icons.flag, 'Nationality', _user!.nationality),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
