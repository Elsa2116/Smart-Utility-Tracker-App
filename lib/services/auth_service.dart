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
    try {
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
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

      return true;
    } catch (e) {
      return false;
    }
  }

  /// -----------------------
  /// LOGIN
  /// -----------------------
  Future<bool> login(String email, String password) async {
    try {
      final user = await _dbHelper.getUserByEmail(email);
      if (user != null && user.password == password) {
        _currentUserId = user.id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', user.id!);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// -----------------------
  /// LOGOUT
  /// -----------------------
  Future<void> logout() async {
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  /// -----------------------
  /// CHECK LOGIN STATUS
  /// -----------------------
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      _currentUserId = userId;
      return true;
    }
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
}
