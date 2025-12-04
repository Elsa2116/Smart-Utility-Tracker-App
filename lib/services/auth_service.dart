import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'db_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final DBHelper _dbHelper = DBHelper();
  int? _currentUserId;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  int? get currentUserId => _currentUserId;

  /// -----------------------
  /// REGISTER
  /// -----------------------
  Future<bool> register(String name, String email, String password) async {
    print('AuthService: Register called for email: $email');
    try {
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        print('AuthService: User already exists');
        return false; // User already exists
      }

      final user = User(
        name: name,
        email: email,
        password: password,
        createdAt: DateTime.now(),
      );

      final userId = await _dbHelper.insertUser(user);
      _currentUserId = userId;

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
  Future<bool> login(String email, String password) async {
    print('AuthService: Login attempt for email: $email');
    try {
      final user = await _dbHelper.getUserByEmail(email);
      if (user != null && user.password == password) {
        _currentUserId = user.id;
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
  Future<void> logout() async {
    print('AuthService: ========= LOGOUT STARTED =========');
    print('AuthService: Current userId before logout: $_currentUserId');

    final prefs = await SharedPreferences.getInstance();

    // Check what's stored BEFORE clearing
    final userIdBefore = prefs.getInt('userId');
    final allKeys = prefs.getKeys();
    print('AuthService: SharedPreferences keys before logout: $allKeys');
    print('AuthService: userId in SharedPreferences before: $userIdBefore');

    // Clear local state
    _currentUserId = null;

    // Clear SharedPreferences
    await prefs.remove('userId');

    // Verify after clearing
    final userIdAfter = prefs.getInt('userId');
    print('AuthService: userId in SharedPreferences after: $userIdAfter');
    print('AuthService: Current userId after logout: $_currentUserId');

    // Check if anything else is stored
    final remainingKeys = prefs.getKeys();
    print('AuthService: Remaining SharedPreferences keys: $remainingKeys');

    print('AuthService: ========= LOGOUT COMPLETED =========');

    // Force a small delay to ensure everything is cleared
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// -----------------------
  /// CHECK LOGIN STATUS
  /// -----------------------
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
  Future<bool> verifyPasscode(String input) async {
    // Example: hardcoded passcode, can later be stored per user in DB
    const String correctPasscode = "1234";

    // Simulate async delay (like checking database)
    await Future.delayed(const Duration(milliseconds: 200));
    return input == correctPasscode;
  }

  /// -----------------------
  /// DEBUG METHOD: Check current state
  /// -----------------------
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
