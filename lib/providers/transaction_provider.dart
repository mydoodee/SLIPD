import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/duplicate_checker.dart';
import '../utils/hash_utils.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final DuplicateChecker _duplicateChecker = DuplicateChecker();

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _searchQuery;
  String? _filterType;

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get searchQuery => _searchQuery;
  String? get filterType => _filterType;

  /// โหลด categories ทั้งหมด
  Future<void> loadCategories({String? type}) async {
    _categories = await _db.getCategories(type: type);
    notifyListeners();
  }

  /// โหลด transactions
  Future<void> loadTransactions({
    String? type,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _db.getTransactions(
        type: type ?? _filterType,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        searchQuery: searchQuery ?? _searchQuery,
      );
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// เพิ่มรายการใหม่
  Future<AddTransactionResult> addTransaction(TransactionModel transaction) async {
    // สร้าง hash สำหรับ duplicate check
    final hash = HashUtils.generateTransactionHash(
      date: transaction.transactionDate,
      amount: transaction.amount,
      refNo: transaction.refNo,
    );

    final txnWithHash = transaction.copyWith(hash: hash);

    // ตรวจ duplicate
    final dupResult = await _duplicateChecker.check(
      date: transaction.transactionDate,
      amount: transaction.amount,
      refNo: transaction.refNo,
    );

    if (dupResult.isDuplicate) {
      return AddTransactionResult(
        success: false,
        message: 'รายการนี้มีอยู่แล้ว (ซ้ำ)\nThis transaction already exists (duplicate)',
      );
    }

    final id = await _db.insertTransaction(txnWithHash);

    if (id > 0) {
      await loadTransactions();
      return AddTransactionResult(
        success: true,
        message: 'บันทึกสำเร็จ / Saved successfully',
      );
    }

    return AddTransactionResult(
      success: false,
      message: 'เกิดข้อผิดพลาด / Error occurred',
    );
  }

  /// อัพเดทรายการ
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _db.updateTransaction(transaction);
    await loadTransactions();
  }

  /// ลบรายการ
  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    await loadTransactions();
  }

  /// ตั้งค่า filter
  void setFilter({String? type, String? search}) {
    _filterType = type;
    _searchQuery = search;
    loadTransactions();
  }

  /// ล้าง filter
  void clearFilters() {
    _filterType = null;
    _searchQuery = null;
    loadTransactions();
  }

  /// หา category ID จากชื่อ
  int? findCategoryIdByName(String? name) {
    if (name == null) return null;
    try {
      return _categories.firstWhere((c) => c.name == name).id;
    } catch (_) {
      return null;
    }
  }
}

class AddTransactionResult {
  final bool success;
  final String message;

  const AddTransactionResult({
    required this.success,
    required this.message,
  });
}
