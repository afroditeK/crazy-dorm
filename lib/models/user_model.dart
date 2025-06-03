class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? description;
  final String? nationality;
  final String? room;
  final String? emojiAvatar;
  final String? phone;
  final String? faculty;
  final List<String> friends;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.description,
    this.nationality,
    this.room,
    this.emojiAvatar,
    this.phone,
    this.faculty,
    this.friends = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      description: map['description'],
      nationality: map['nationality'],
      room: map['room'],
      emojiAvatar: map['emojiAvatar'],
      phone: map['phone'],
      faculty: map['faculty'],
      friends: map['friends'] != null
          ? List<String>.from(map['friends'] as List<dynamic>)
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'description': description,
      'nationality': nationality,
      'room': room,
      'emojiAvatar': emojiAvatar,
      'phone': phone,
      'faculty': faculty,
      'friends': friends,
    };
  }
}
