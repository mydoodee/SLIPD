import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat('#,##0.00', 'th_TH');
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'th_TH');
  static final _timeFormat = DateFormat('HH:mm', 'th_TH');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'th_TH');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'th_TH');
  static final _shortDateFormat = DateFormat('dd MMM', 'th_TH');

  /// Format จำนวนเงิน เช่น 1,500.00
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format จำนวนเงินพร้อมสกุล เช่น ฿1,500.00
  static String formatCurrencyWithSymbol(double amount) {
    return '฿${_currencyFormat.format(amount)}';
  }

  /// Format วันที่ เช่น 03/06/2026
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format เวลา เช่น 14:35
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format วันที่+เวลา เช่น 03/06/2026 14:35
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format เดือน-ปี เช่น มิถุนายน 2026
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format วันที่สั้น เช่น 03 มิ.ย.
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// แสดง "วันนี้", "เมื่อวาน", หรือวันที่
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'วันนี้ / Today';
    if (diff == 1) return 'เมื่อวาน / Yesterday';
    if (diff < 7) return '$diff วันที่แล้ว / $diff days ago';
    return formatDate(date);
  }
}
