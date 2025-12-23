import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'db_helper.dart';

/// AuthService is a singleton class that handles user authentication,
/// including registration, login, logout, and login status checks.
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();

  // Database helper instance to interact with SQLite or other DB
  final DBHelper _dbHelper = DBHelper();

  // Stores the currently logged-in user's ID in memory
  int? _currentUserId;

  // Factory constructor for singleton pattern
  factory AuthService() {
    return _instance;
  }

  // Private constructor
  AuthService._internal();

  // Getter for current user ID
  int? get currentUserId => _currentUserId;

  /// -----------------------
  /// REGISTER NEW USER
  /// -----------------------
  /// Registers a new user in the database and saves their ID in SharedPreferences.
  /// Returns true if registration is successful, false if user already exists or error occurs.
  Future<bool> register(String name, String email, String password) async {
    print('AuthService: Register called for email: $email');
    try {
      // Check if user already exists by email
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        print('AuthService: User already exists');
        return false; // Registration fails if user exists
      }

      // Create new User object
      final user = User(
        name: name,
        email: email,
        password: password,
        createdAt: DateTime.now(),
      );

      // Insert user into database and get the generated userId
      final userId = await _dbHelper.insertUser(user);

      // Store userId in memory
      _currentUserId = userId;

      // Save userId in SharedPreferences to persist login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', userId);

      print('AuthService: Registration successful, userId: $userId');

      return true;
    } catch (e) {
      print('AuthService: Register error: $e');
      return false;
    }
  }

  /// -----------------------
  /// LOGIN
  /// -----------------------
  /// Authenticates a user by email and password.
  /// Saves the userId in memory and SharedPreferences if successful.
  Future<bool> login(String email, String password) async {
    print('AuthService: Login attempt for email: $email');
    try {
      // Get user from database by email
      final user = await _dbHelper.getUserByEmail(email);

      // Check password
      if (user != null && user.password == password) {
        _currentUserId = user.id;

        // Save userId in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', user.id!);

        print('AuthService: Login successful, userId: ${user.id}');
        print('AuthService: Saved userId to SharedPreferences');

        return true;
      }

      print('AuthService: Login failed - invalid credentials');
      return false;
    } catch (e) {
      print('AuthService: Login error: $e');
      return false;
    }
  }

  /// -----------------------
  /// LOGOUT
  /// -----------------------
  /// Logs out the current user by clearing memory and SharedPreferences.
  Future<void> logout() async {
    print('AuthService: ========= LOGOUT STARTED =========');
    print('AuthService: Current userId before logout: $_currentUserId');

    final prefs = await SharedPreferences.getInstance();

    // Check what's stored BEFORE clearing
    final userIdBefore = prefs.getInt('userId');
    final allKeys = prefs.getKeys();
    print('AuthService: SharedPreferences keys before logout: $allKeys');
    print('AuthService: userId in SharedPreferences before: $userIdBefore');

    // Clear in-memory userId
    _currentUserId = null;

    // Remove userId from SharedPreferences
    await prefs.remove('userId');

    // Verify removal
    final userIdAfter = prefs.getInt('userId');
    print('AuthService: userId in SharedPreferences after: $userIdAfter');
    print('AuthService: Current userId after logout: $_currentUserId');

    // Remaining keys in SharedPreferences
    final remainingKeys = prefs.getKeys();
    print('AuthService: Remaining SharedPreferences keys: $remainingKeys');

    print('AuthService: ========= LOGOUT COMPLETED =========');

    // Small delay to ensure async clearing is done
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// -----------------------
  /// CHECK LOGIN STATUS
  /// -----------------------
  /// Checks if a user is logged in by reading userId from SharedPreferences.
  /// Returns true if logged in, false otherwise.
  Future<bool> checkLoginStatus() async {
    print('AuthService: ========= CHECKING LOGIN STATUS =========');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    print('AuthService: Retrieved userId from SharedPreferences: $userId');
    print('AuthService: Current userId in memory: $_currentUserId');

    if (userId != null) {
      _currentUserId = userId;
      print('AuthService: User is LOGGED IN (userId: $userId)');
      return true;
    }

    print('AuthService: User is NOT LOGGED IN');
    return false;
  }

  /// -----------------------
  /// VERIFY PASSCODE
  /// -----------------------
  /// Example method to verify a passcode.
  /// Currently uses a hardcoded value for demonstration.
  Future<bool> verifyPasscode(String input) async {
    const String correctPasscode = "1234";

    // Simulate a small async delay as if checking a DB
    await Future.delayed(const Duration(milliseconds: 200));
    return input == correctPasscode;
  }

  /// -----------------------
  /// DEBUG METHOD: Check current state
  /// -----------------------
  /// Prints current in-memory and SharedPreferences state for debugging.
  Future<void> debugCurrentState() async {
    print('AuthService: ========= DEBUG STATE =========');
    print('AuthService: Memory - _currentUserId: $_currentUserId');

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final allKeys = prefs.getKeys();

    print('AuthService: SharedPreferences - userId: $userId');
    print('AuthService: SharedPreferences - all keys: $allKeys');

    for (var key in allKeys) {
      final value = prefs.get(key);
      print('AuthService:   $key: $value');
    }

    print('AuthService: ===============================');
  }
}
