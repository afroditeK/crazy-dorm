import 'package:crazy_dorm/main.dart';
import 'package:crazy_dorm/screens/chores_screen.dart';
import 'package:crazy_dorm/screens/home_screen.dart';
import 'package:crazy_dorm/screens/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crazy_dorm/models/user_model.dart'; // Your UserModel class
import 'package:crazy_dorm/theme/app_theme.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _roomController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedFaculty;
  String? _selectedNationality;

  bool _isLoading = false;

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _roomController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFaculty == null || _selectedNationality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select faculty and nationality')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user with email/password
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Get uid directly from created user
      final String uid = userCredential.user!.uid;

      // Create UserModel and save in Firestore
      final newUser = UserModel(
        uid: uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        faculty: _selectedFaculty,
        nationality: _selectedNationality!,
        room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        emojiAvatar: null, // or assign a default if needed
        friends: [], // initialize empty friends list explicitly
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set(newUser.toMap());

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => _isLoading = false);
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        // backgroundColor: Colors.teal.shade600,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  _emailController,
                  'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter email';
                    if (!value.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _passwordController,
                  'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _nameController,
                  'Name',
                  validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(_descController, 'Description', maxLines: 3),
                const SizedBox(height: 12),
                _buildTextField(_roomController, 'Room'),
                const SizedBox(height: 12),
                _buildTextField(_phoneController, 'Phone', keyboardType: TextInputType.phone),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedFaculty,
                  decoration: InputDecoration(
                    labelText: 'Faculty',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _faculties.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) => setState(() => _selectedFaculty = val),
                  validator: (val) => val == null ? 'Select faculty' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedNationality,
                  decoration: InputDecoration(
                    labelText: 'Nationality',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _countries
                      .map((c) => DropdownMenuItem(
                            value: c['name'],
                            child: Text('${c['flag']} ${c['name']}'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedNationality = val),
                  validator: (val) => val == null ? 'Select nationality' : null,
                ),
                const SizedBox(height: 24),

                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Register', style: TextStyle(fontSize: 18)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
