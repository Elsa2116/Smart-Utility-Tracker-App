class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final DateTime createdAt;
  final String? profileImageUrl;
  final DateTime? updatedAt; // Missing in your current model
  final bool? isActive; // Optional field for future use

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
    this.profileImageUrl,
    this.updatedAt,
    this.isActive = true,
  });

  // Copy with method for immutability
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    DateTime? createdAt,
    String? profileImageUrl,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      // Note: isActive is not in your database schema yet
      // 'isActive': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      profileImageUrl: map['profileImageUrl'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      // isActive: map['isActive'] != null ? (map['isActive'] as int) == 1 : true,
    );
  }

  // For JSON serialization
  Map<String, dynamic> toJson() => toMap();

  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, profileImageUrl: $profileImageUrl)';
  }
}
