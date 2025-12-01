class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final DateTime createdAt;
  final String? profileImageUrl; // Add this field

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
    this.profileImageUrl, // Add this parameter
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'profileImageUrl': profileImageUrl, // Add this line
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      createdAt: DateTime.parse(map['createdAt']),
      profileImageUrl: map['profileImageUrl'], // Add this line
    );
  }
}
