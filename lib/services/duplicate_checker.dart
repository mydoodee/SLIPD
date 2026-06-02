import '../database/database_helper.dart';
import '../utils/hash_utils.dart';

/// ตรวจสอบรายการซ้ำก่อนบันทึก
/// Check for duplicate transactions before saving
class DuplicateChecker {
  final DatabaseHelper _db;

  DuplicateChecker({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  /// สร้าง hash และตรวจสอบว่ามีอยู่แล้วหรือไม่
  /// Generate hash and check if it already exists
  Future<DuplicateCheckResult> check({
    required DateTime date,
    required double amount,
    String? refNo,
  }) async {
    final hash = HashUtils.generateTransactionHash(
      date: date,
      amount: amount,
      refNo: refNo,
    );

    final exists = await _db.hashExists(hash);

    return DuplicateCheckResult(
      hash: hash,
      isDuplicate: exists,
    );
  }
}

class DuplicateCheckResult {
  final String hash;
  final bool isDuplicate;

  const DuplicateCheckResult({
    required this.hash,
    required this.isDuplicate,
  });
}
