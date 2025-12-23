/// Represents a user in the utility tracker system.
///
/// Contains personal information, authentication details, and optional metadata
/// such as profile image, updated time, and active status.
class User {
  // Unique ID of the user (auto-incremented in the database)
  final int? id;

  // Full name of the user
  final String name;

  // Email address of the user (unique)
  final String email;

  // User password (hashed or plain depending on your implementation)
  final String password;

  // Date and time when the user account was created
  final DateTime createdAt;

  // Optional URL for the user's profile image
  final String? profileImageUrl;

  // Optional last updated timestamp
  final DateTime? updatedAt;

  // Optional flag indicating if the account is active (default: true)
  final bool? isActive;

  // Constructor for creating a User object
  User({
    this.id, // optional, DB generates it
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
    this.profileImageUrl,
    this.updatedAt,
    this.isActive = true, // default active
  });

  /// Creates a copy of the User object with optional modifications
  /// Useful for immutability and updating specific fields
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

  /// Converts the User object to a Map for storing in the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'createdAt': createdAt.toIso8601String(), // Store as ISO string
      'profileImageUrl': profileImageUrl,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      // Note: isActive is not yet stored in DB
      // 'isActive': isActive ? 1 : 0,
    };
  }

  /// Creates a User object from a Map (retrieved from the database)
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

  /// Converts User object to JSON (for API or storage)
  Map<String, dynamic> toJson() => toMap();

  /// Creates a User object from JSON
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, profileImageUrl: $profileImageUrl)';
  }
}
