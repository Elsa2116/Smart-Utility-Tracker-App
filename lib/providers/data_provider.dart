import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/reading.dart';
import '../models/threshold.dart';
import '../models/payment.dart';
import '../models/alert.dart';

/// A ChangeNotifier provider for managing and syncing app data with the database.
///
/// This class handles CRUD operations for Readings, Thresholds, Payments, and Alerts,
/// and notifies listeners when the data changes so the UI can update automatically.
class DataProvider extends ChangeNotifier {
  // Database helper instance for performing DB operations
  final DBHelper _dbHelper = DBHelper();

  // The current logged-in user's ID
  int? userId;

  // Lists to store data fetched from the database
  List<Reading> readings = [];
  List<UsageThreshold> thresholds = [];
  List<Payment> payments = [];
  List<Alert> alerts = [];

  /// Set the current user ID and load all associated data
  void setUserId(int id) {
    userId = id;
    loadAllData(); // Load readings, thresholds, payments, and alerts for this user
  }

  /// Load all user-related data from the database
  Future<void> loadAllData() async {
    if (userId == null) return; // If no user is set, do nothing

    // Fetch data from the database
    readings = await _dbHelper.getReadingsByUserId(userId!);
    thresholds = await _dbHelper.getThresholdsByUserId(userId!);
    payments = await _dbHelper.getPaymentsByUserId(userId!);
    alerts = await _dbHelper.getAlertsByUserId(userId!);

    notifyListeners(); // Notify UI listeners that data has changed
  }

  /// Add a new reading and refresh data
  Future<void> addReading(Reading r) async {
    await _dbHelper.insertReading(r); // Insert reading into DB
    await loadAllData(); // Reload all data and update UI
  }

  /// Add or update a usage threshold and refresh data
  Future<void> addOrUpdateThreshold(UsageThreshold t) async {
    await _dbHelper.insertThreshold(t); // Insert or update threshold in DB
    await loadAllData(); // Reload all data and update UI
  }

  /// Add a new payment and refresh data
  Future<void> addPayment(Payment p) async {
    await _dbHelper.insertPayment(p); // Insert payment into DB
    await loadAllData(); // Reload all data and update UI
  }

  /// Update the status of a payment (e.g., pending → completed) and refresh data
  Future<void> updatePaymentStatus(int id, String status) async {
    await _dbHelper.updatePaymentStatus(
        id, status); // Update payment status in DB
    await loadAllData(); // Reload all data and update UI
  }

  /// Add a new alert and refresh data
  Future<void> addAlert(Alert a) async {
    await _dbHelper.insertAlert(a); // Insert alert into DB
    await loadAllData(); // Reload all data and update UI
  }
}
