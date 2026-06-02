import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'slipd.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        // สร้างตาราง processed_assets สำหรับบันทึกรูปภาพที่เคยแสกนแกลเลอรีแล้ว
        await db.execute('''
          CREATE TABLE IF NOT EXISTS processed_assets (
            asset_id TEXT PRIMARY KEY,
            scanned_at TEXT NOT NULL,
            is_slip INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // สร้างตาราง categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // สร้างตาราง transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        bank_name TEXT,
        sender TEXT,
        receiver TEXT,
        ref_no TEXT,
        note TEXT,
        image_path TEXT,
        category_id INTEGER,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        hash TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // สร้าง index สำหรับ hash (duplicate check)
    await db.execute(
      'CREATE UNIQUE INDEX idx_transaction_hash ON transactions(hash)'
    );

    // สร้าง index สำหรับวันที่ (query performance)
    await db.execute(
      'CREATE INDEX idx_transaction_date ON transactions(transaction_date)'
    );

    // Insert seed categories
    for (final category in SeedData.defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  // ==================== CATEGORY OPERATIONS ====================

  Future<List<CategoryModel>> getCategories({String? type}) async {
    final db = await database;
    List<Map<String, dynamic>> result;

    if (type != null) {
      result = await db.query(
        'categories',
        where: 'type = ? OR type = ?',
        whereArgs: [type, 'both'],
      );
    } else {
      result = await db.query('categories');
    }

    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return CategoryModel.fromMap(result.first);
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  // ==================== TRANSACTION OPERATIONS ====================

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // ข้าม hash ซ้ำ
    );
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT t.*, c.name as category_name
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.id = ?
    ''', [id]);

    if (result.isEmpty) return null;
    return TransactionModel.fromMap(result.first);
  }

  Future<List<TransactionModel>> getTransactions({
    String? type,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      where.add('t.type = ?');
      args.add(type);
    }

    if (categoryId != null) {
      where.add('t.category_id = ?');
      args.add(categoryId);
    }

    if (startDate != null) {
      where.add('t.transaction_date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.add('t.transaction_date <= ?');
      args.add(endDate.toIso8601String());
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('(t.note LIKE ? OR t.sender LIKE ? OR t.receiver LIKE ? OR t.bank_name LIKE ?)');
      final q = '%$searchQuery%';
      args.addAll([q, q, q, q]);
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final result = await db.rawQuery('''
      SELECT t.*, c.name as category_name
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      $whereClause
      ORDER BY t.transaction_date DESC
      $limitClause $offsetClause
    ''', args);

    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // ==================== DASHBOARD QUERIES ====================

  /// สรุปรายรับ-รายจ่ายของวันที่กำหนด
  Future<Map<String, double>> getDailySummary(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      GROUP BY type
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    double income = 0;
    double expense = 0;

    for (final row in result) {
      if (row['type'] == 'income') {
        income = (row['total'] as num).toDouble();
      } else {
        expense = (row['total'] as num).toDouble();
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  /// สรุปรายเดือน (สำหรับ chart)
  Future<List<Map<String, dynamic>>> getMonthlySummary(int year) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        CAST(strftime('%m', transaction_date) AS INTEGER) as month,
        type,
        SUM(amount) as total
      FROM transactions
      WHERE strftime('%Y', transaction_date) = ?
      GROUP BY month, type
      ORDER BY month
    ''', [year.toString()]);

    // สร้าง map สำหรับทุกเดือน
    final months = <Map<String, dynamic>>[];
    for (int m = 1; m <= 12; m++) {
      double income = 0;
      double expense = 0;

      for (final row in result) {
        if (row['month'] == m) {
          if (row['type'] == 'income') {
            income = (row['total'] as num).toDouble();
          } else {
            expense = (row['total'] as num).toDouble();
          }
        }
      }

      months.add({
        'month': m,
        'income': income,
        'expense': expense,
        'balance': income - expense,
      });
    }

    return months;
  }

  /// สรุปตามหมวดหมู่ (สำหรับ pie chart)
  Future<List<Map<String, dynamic>>> getCategorySummary({
    required String type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final where = <String>['t.type = ?'];
    final args = <dynamic>[type];

    if (startDate != null) {
      where.add('t.transaction_date >= ?');
      args.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where.add('t.transaction_date <= ?');
      args.add(endDate.toIso8601String());
    }

    final whereClause = where.join(' AND ');

    final result = await db.rawQuery('''
      SELECT
        c.name as category_name,
        c.icon as category_icon,
        SUM(t.amount) as total,
        COUNT(t.id) as count
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE $whereClause
      GROUP BY t.category_id
      ORDER BY total DESC
    ''', args);

    return result;
  }

  // ==================== DUPLICATE CHECK ====================

  Future<bool> hashExists(String hash) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'hash = ?',
      whereArgs: [hash],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ==================== PROCESSED ASSETS (GALLERY SCAN) ====================

  /// บันทึกว่ารูปภาพในแกลเลอรีนี้ถูกสแกนแล้ว
  Future<void> markAssetProcessed(String assetId, bool isSlip) async {
    final db = await database;
    await db.insert(
      'processed_assets',
      {
        'asset_id': assetId,
        'scanned_at': DateTime.now().toIso8601String(),
        'is_slip': isSlip ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ตรวจสอบว่ารูปภาพนี้เคยสแกนแล้วหรือไม่
  Future<bool> isAssetProcessed(String assetId) async {
    final db = await database;
    final result = await db.query(
      'processed_assets',
      columns: ['asset_id'],
      where: 'asset_id = ?',
      whereArgs: [assetId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// ค้นหารหัสภาพที่เคยประมวลผลไปแล้วจากกลุ่มรายการที่ส่งเข้ามา
  Future<Set<String>> getProcessedAssetIds(List<String> assetIds) async {
    if (assetIds.isEmpty) return {};
    final db = await database;
    
    final Set<String> processed = {};
    // แบ่งกลุ่มย่อยกลุ่มละ 50 เพื่อป้องกัน SQLite variable limit
    for (int i = 0; i < assetIds.length; i += 50) {
      final chunk = assetIds.sublist(
        i,
        i + 50 > assetIds.length ? assetIds.length : i + 50,
      );
      final placeholders = List.filled(chunk.length, '?').join(',');
      final result = await db.query(
        'processed_assets',
        columns: ['asset_id'],
        where: 'asset_id IN ($placeholders)',
        whereArgs: chunk,
      );
      for (final row in result) {
        processed.add(row['asset_id'] as String);
      }
    }
    return processed;
  }

  /// ล้างประวัติรูปภาพที่สแกนไปแล้ว เพื่อให้เริ่มสแกนใหม่ทั้งหมดได้
  Future<int> clearProcessedAssets() async {
    final db = await database;
    return await db.delete('processed_assets');
  }
}
