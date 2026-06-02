import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DashboardProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  Map<String, double> _todaySummary = {'income': 0, 'expense': 0, 'balance': 0};
  Map<String, double> _monthSummary = {'income': 0, 'expense': 0, 'balance': 0};
  List<Map<String, dynamic>> _monthlySummary = [];
  List<Map<String, dynamic>> _categorySummary = [];
  bool _isLoading = false;
  int _selectedYear = DateTime.now().year;

  Map<String, double> get todaySummary => _todaySummary;
  Map<String, double> get monthSummary => _monthSummary;
  List<Map<String, dynamic>> get monthlySummary => _monthlySummary;
  List<Map<String, dynamic>> get categorySummary => _categorySummary;
  bool get isLoading => _isLoading;
  int get selectedYear => _selectedYear;

  /// โหลดข้อมูลทั้งหมดสำหรับ Dashboard
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadTodaySummary(),
        _loadMonthSummary(),
        _loadMonthlySummary(),
        _loadCategorySummary(),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTodaySummary() async {
    _todaySummary = await _db.getDailySummary(DateTime.now());
  }

  Future<void> _loadMonthSummary() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // ใช้ getDailySummary range-style ด้วยการ query ใหม่
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date <= ?
      GROUP BY type
    ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    double income = 0;
    double expense = 0;
    for (final row in result) {
      if (row['type'] == 'income') {
        income = (row['total'] as num).toDouble();
      } else {
        expense = (row['total'] as num).toDouble();
      }
    }

    _monthSummary = {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  Future<void> _loadMonthlySummary() async {
    _monthlySummary = await _db.getMonthlySummary(_selectedYear);
  }

  Future<void> _loadCategorySummary() async {
    final now = DateTime.now();
    _categorySummary = await _db.getCategorySummary(
      type: 'expense',
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  void setYear(int year) {
    _selectedYear = year;
    _loadMonthlySummary().then((_) => notifyListeners());
  }
}
