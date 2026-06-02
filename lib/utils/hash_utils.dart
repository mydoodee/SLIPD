import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtils {
  /// สร้าง SHA256 hash จากข้อมูลสลิป เพื่อป้องกันการบันทึกซ้ำ
  /// Generate SHA256 hash from slip data to prevent duplicates
  static String generateTransactionHash({
    required DateTime date,
    required double amount,
    String? refNo,
  }) {
    final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}';
    final amountStr = amount.toStringAsFixed(2);
    final ref = refNo ?? '';

    final input = '$dateStr$timeStr$amountStr$ref';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }
}
