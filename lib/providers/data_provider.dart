import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/reading.dart';
import '../models/threshold.dart';
import '../models/payment.dart';
import '../models/alert.dart';

class DataProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  int? userId;
  List<Reading> readings = [];
  List<UsageThreshold> thresholds = [];
  List<Payment> payments = [];
  List<Alert> alerts = [];

  void setUserId(int id) {
    userId = id;
    loadAllData();
  }

  Future<void> loadAllData() async {
    if (userId == null) return;

    readings = await _dbHelper.getReadingsByUserId(userId!);
    thresholds = await _dbHelper.getThresholdsByUserId(userId!);
    payments = await _dbHelper.getPaymentsByUserId(userId!);
    alerts = await _dbHelper.getAlertsByUserId(userId!);

    notifyListeners();
  }

  Future<void> addReading(Reading r) async {
    await _dbHelper.insertReading(r);
    await loadAllData();
  }

  Future<void> addOrUpdateThreshold(UsageThreshold t) async {
    await _dbHelper.insertThreshold(t);
    await loadAllData();
  }

  Future<void> addPayment(Payment p) async {
    await _dbHelper.insertPayment(p);
    await loadAllData();
  }

  Future<void> updatePaymentStatus(int id, String status) async {
    await _dbHelper.updatePaymentStatus(id, status);
    await loadAllData();
  }

  Future<void> addAlert(Alert a) async {
    await _dbHelper.insertAlert(a);
    await loadAllData();
  }
}
