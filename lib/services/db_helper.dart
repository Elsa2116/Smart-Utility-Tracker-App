import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/reading.dart';
import '../models/payment.dart';
import '../models/threshold.dart';
import '../models/alert.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'utility_tracker.db');

    return openDatabase(
      path,
      version: 4, // Incremented version to add profileImageUrl column
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        profileImageUrl TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        usage REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        paymentMethod TEXT NOT NULL DEFAULT 'telebirr',
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        notes TEXT,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE thresholds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        type TEXT NOT NULL,
        maxUsage REAL NOT NULL,
        unit TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id),
        UNIQUE(userId, type)
      )
    ''');

    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        type TEXT NOT NULL,
        usage REAL NOT NULL,
        threshold REAL NOT NULL,
        date TEXT NOT NULL,
        message TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
            'ALTER TABLE payments ADD COLUMN paymentMethod TEXT NOT NULL DEFAULT "telebirr"');
      } catch (e) {
        print('[DB] Column paymentMethod already exists: $e');
      }

      try {
        await db.execute(
            'ALTER TABLE payments ADD COLUMN status TEXT NOT NULL DEFAULT "pending"');
      } catch (e) {
        print('[DB] Column status already exists: $e');
      }
    }

    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS thresholds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            type TEXT NOT NULL,
            maxUsage REAL NOT NULL,
            unit TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users(id),
            UNIQUE(userId, type)
          )
        ''');
      } catch (e) {
        print('[DB] Thresholds table already exists: $e');
      }

      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            type TEXT NOT NULL,
            usage REAL NOT NULL,
            threshold REAL NOT NULL,
            date TEXT NOT NULL,
            message TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users(id)
          )
        ''');
      } catch (e) {
        print('[DB] Alerts table already exists: $e');
      }
    }

    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profileImageUrl TEXT');
        print('[DB] Added profileImageUrl column to users table');
      } catch (e) {
        print('[DB] Column profileImageUrl already exists: $e');
      }
    }
  }

  // ========== USER OPERATIONS ==========

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final result =
        await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // ADD THIS METHOD: Get user by ID
  Future<User?> getUserById(int userId) async {
    final db = await database;
    final result =
        await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // ADD THIS METHOD: Update user
  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ADD THIS METHOD: Get all users (optional, for debugging)
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  // ADD THIS METHOD: Delete user
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  // ========== READING OPERATIONS ==========

  Future<int> insertReading(Reading reading) async {
    final db = await database;
    return await db.insert('readings', reading.toMap());
  }

  Future<List<Reading>> getReadingsByUserId(int userId) async {
    final db = await database;
    final result = await db.query('readings',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'date DESC');
    return result.map((map) => Reading.fromMap(map)).toList();
  }

  Future<List<Reading>> getReadingsByType(int userId, String type) async {
    final db = await database;
    final result = await db.query('readings',
        where: 'userId = ? AND type = ?',
        whereArgs: [userId, type],
        orderBy: 'date DESC');
    return result.map((map) => Reading.fromMap(map)).toList();
  }

  Future<List<Reading>> getReadingsForPrediction(int userId, String type,
      {int months = 3}) async {
    final db = await database;
    final threeMonthsAgo =
        DateTime.now().subtract(Duration(days: months * 30)).toIso8601String();
    final result = await db.query(
      'readings',
      where: 'userId = ? AND type = ? AND date >= ?',
      whereArgs: [userId, type, threeMonthsAgo],
      orderBy: 'date ASC',
    );
    return result.map((map) => Reading.fromMap(map)).toList();
  }

  Future<int> deleteReading(int id) async {
    final db = await database;
    return await db.delete('readings', where: 'id = ?', whereArgs: [id]);
  }

  // ========== PAYMENT OPERATIONS ==========

  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getPaymentsByUserId(int userId) async {
    final db = await database;
    final result = await db.query('payments',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'date DESC');
    return result.map((map) => Payment.fromMap(map)).toList();
  }

  Future<int> updatePaymentStatus(int id, String status) async {
    final db = await database;
    return await db.update('payments', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // ========== THRESHOLD OPERATIONS ==========

  Future<int> insertThreshold(UsageThreshold threshold) async {
    final db = await database;

    // Ensure thresholds table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS thresholds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        type TEXT NOT NULL,
        maxUsage REAL NOT NULL,
        unit TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id),
        UNIQUE(userId, type)
      )
    ''');

    return await db.insert(
      'thresholds',
      threshold.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UsageThreshold?> getThreshold(int userId, String type) async {
    final db = await database;
    final result = await db.query('thresholds',
        where: 'userId = ? AND type = ?', whereArgs: [userId, type]);
    if (result.isNotEmpty) {
      return UsageThreshold.fromMap(result.first);
    }
    return null;
  }

  Future<List<UsageThreshold>> getThresholdsByUserId(int userId) async {
    final db = await database;
    final result =
        await db.query('thresholds', where: 'userId = ?', whereArgs: [userId]);
    return result.map((map) => UsageThreshold.fromMap(map)).toList();
  }

  // ========== ALERT OPERATIONS ==========

  Future<int> insertAlert(Alert alert) async {
    final db = await database;
    return await db.insert('alerts', alert.toMap());
  }

  Future<List<Alert>> getAlertsByUserId(int userId) async {
    final db = await database;
    final result = await db.query('alerts',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'date DESC');
    return result.map((map) => Alert.fromMap(map)).toList();
  }

  Future<int> deleteAlert(int id) async {
    final db = await database;
    return await db.delete('alerts', where: 'id = ?', whereArgs: [id]);
  }

  // ========== DATABASE MAINTENANCE ==========

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // FIXED THIS METHOD
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'utility_tracker.db');
    try {
      await databaseFactory.deleteDatabase(path);
      _database = null; // Reset the database instance
      print('[DB] Database reset successfully');
    } catch (e) {
      print('[DB] Error resetting database: $e');
    }
  }
}
