import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crazy_dorm/models/user_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crazy_dorm/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final bool isSelf;

  const ProfilePage({Key? key, required this.userId, required this.isSelf}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _roomController;
  late TextEditingController _phoneController;

  bool _isSaving = false;
  bool _isEditing = false;
  UserModel? _user;

  String? _selectedFaculty;
  String? _selectedNationality;

  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

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

  final List<String> _faculties = [
    'Engineering',
    'Economics',
    'Humanities',
    'Social Sciences',
    'Natural Sciences',
    'Medicine',
    'Law',
    'Arts',
    'Computer Science',
    'Business Administration',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _user = UserModel.fromMap(data);
        _nameController = TextEditingController(text: _user!.name);
        _descController = TextEditingController(text: _user!.description ?? '');
        _roomController = TextEditingController(text: _user!.room ?? '');
        _phoneController = TextEditingController(text: _user!.phone ?? '');
        _selectedFaculty = _user!.faculty;
        _selectedNationality = _user!.nationality;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _roomController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_user == null) return;
    setState(() => _isSaving = true);

    try {
      final updatedUser = UserModel(
        uid: _user!.uid,
        name: _nameController.text.trim(),
        email: _user!.email,
        description: _descController.text.trim(),
        nationality: _selectedNationality ?? '',
        room: _roomController.text.trim(),
        emojiAvatar: _user!.emojiAvatar,
        phone: _phoneController.text.trim(),
        faculty: _selectedFaculty,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedUser.uid)
          .set(updatedUser.toMap(), SetOptions(merge: true));

      setState(() {
        _user = updatedUser;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }

    setState(() => _isSaving = false);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _sendFriendRequest() async {
    if (currentUserId == null || widget.userId == currentUserId) return;

    final friendReqDoc = FirebaseFirestore.instance
        .collection('friend_requests')
        .doc('$currentUserId-${widget.userId}');

    final exists = await friendReqDoc.get();
    if (!exists.exists) {
      await friendReqDoc.set({
        'from': currentUserId,
        'to': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend request sent.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request already sent.")));
    }
  }

  String getNationalityFlag(String? nationality) {
    final country = _countries.firstWhere(
      (c) => c['name'] == nationality,
      orElse: () => {'flag': '👤'},
    );
    return country['flag'] ?? '👤';
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 18, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.deepPurple.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  void _showQrCode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('User QR Code', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
            const SizedBox(height: 20),
            QrImageView(data: widget.userId, size: 200),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade50,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.deepPurple.shade700),
                const SizedBox(width: 14),
                Text(
                  '$label:',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.deepPurple.shade800),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.deepPurple.shade900, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isEditable = widget.isSelf;

    return Scaffold(
      // Gradient background with purple shades
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar-like header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _isEditing = false),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Profile' : 'My Profile',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ),
                    if (isEditable)
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.save : Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: _isEditing
                            ? (_isSaving ? null : _saveChanges)
                            : () => setState(() => _isEditing = true),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      child: Column(
                        children: [
                          // Avatar with border and shadow
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.shade200,
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.deepPurple.shade100,
                              child: Text(
                                getNationalityFlag(_selectedNationality ?? _user!.nationality),
                                style: const TextStyle(fontSize: 64),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Name & Description
                          _isEditing
                              ? _buildTextField(_nameController, 'Name')
                              : Text(
                                  _user!.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                          const SizedBox(height: 12),
                          _isEditing
                              ? _buildTextField(_descController, 'Description', maxLines: 3)
                              : Text(
                                  _user!.description ?? 'No description provided.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.deepPurple.shade700),
                                ),
                          const SizedBox(height: 24),

                          // Info section - room, phone, faculty, nationality
                          if (_isEditing)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(_roomController, 'Room'),
                                const SizedBox(height: 14),
                                _buildTextField(_phoneController, 'Phone'),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _selectedFaculty,
                                  decoration: InputDecoration(
                                    labelText: 'Faculty',
                                    filled: true,
                                    fillColor: Colors.deepPurple.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: _faculties
                                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selectedFaculty = val),
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _selectedNationality,
                                  decoration: InputDecoration(
                                    labelText: 'Nationality',
                                    filled: true,
                                    fillColor: Colors.deepPurple.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: _countries
                                      .map((c) => DropdownMenuItem(
                                            value: c['name'],
                                            child: Text('${c['flag']} ${c['name']}'),
                                          ))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selectedNationality = val),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoTile(Icons.room, 'Room', _user!.room),
                                _buildInfoTile(Icons.phone, 'Phone', _user!.phone),
                                _buildInfoTile(Icons.school, 'Faculty', _user!.faculty),
                                _buildInfoTile(Icons.flag, 'Nationality', _user!.nationality),
                              ],
                            ),

                          const SizedBox(height: 30),

                          if (!widget.isSelf)
                            ElevatedButton.icon(
                              onPressed: _sendFriendRequest,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Send Friend Request'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                            ),

                          if (widget.isSelf && !_isEditing)
                            ElevatedButton.icon(
                              onPressed: _showQrCode,
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Show My QR Code'),
                              style: ElevatedButton.styleFrom(
                                // backgroundColor: Colors.deepPurple.shade50,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                            ),

                          if (widget.isSelf && !_isEditing)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: OutlinedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout, color: Colors.deepPurple),
                                label: const Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.deepPurple),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.deepPurple),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
