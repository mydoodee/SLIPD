import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final sign = isIncome ? '+' : '-';

    // ดึง icon จาก category
    final categoryModel = transaction.categoryName != null
        ? _getCategoryIcon(transaction.categoryName!)
        : null;

    return Dismissible(
      key: Key('txn_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.expenseColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.expenseColor),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('ลบรายการ / Delete', style: TextStyle(color: AppTheme.textPrimary)),
            content: const Text(
              'ต้องการลบรายการนี้หรือไม่?\nDelete this transaction?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ยกเลิก / Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.expenseColor),
                child: const Text('ลบ / Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              // Icon หมวดหมู่
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryModel ?? (isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // ข้อมูลรายการ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.note ??
                          transaction.receiver ??
                          transaction.categoryName ??
                          (isIncome ? 'รายรับ / Income' : 'รายจ่าย / Expense'),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (transaction.bankName != null) ...[
                          const Icon(Icons.account_balance, size: 12, color: AppTheme.textMuted),
                          Text(
                            transaction.bankName!.split(' / ').first,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          const SizedBox(width: 4),
                        ],
                        const Icon(Icons.access_time, size: 12, color: AppTheme.textMuted),
                        Text(
                          Formatters.formatDateTime(transaction.transactionDate),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // จำนวนเงิน
              Text(
                '$sign฿${Formatters.formatCurrency(transaction.amount)}',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData? _getCategoryIcon(String categoryName) {
    final iconMap = {
      'อาหาร': Icons.restaurant,
      'Food': Icons.restaurant,
      'ค่าเดินทาง': Icons.directions_car,
      'Transport': Icons.directions_car,
      'ช้อปปิ้ง': Icons.shopping_bag,
      'Shopping': Icons.shopping_bag,
      'ค่าน้ำมัน': Icons.local_gas_station,
      'Fuel': Icons.local_gas_station,
      'บิล': Icons.receipt_long,
      'Bills': Icons.receipt_long,
      'ที่อยู่อาศัย': Icons.home,
      'Housing': Icons.home,
      'การศึกษา': Icons.school,
      'Education': Icons.school,
      'สุขภาพ': Icons.local_hospital,
      'Health': Icons.local_hospital,
      'บันเทิง': Icons.sports_esports,
      'Entertainment': Icons.sports_esports,
      'โทรศัพท์': Icons.phone_android,
      'Phone': Icons.phone_android,
      'เงินเดือน': Icons.work,
      'Salary': Icons.work,
      'โบนัส': Icons.card_giftcard,
      'Bonus': Icons.card_giftcard,
      'รายได้เสริม': Icons.trending_up,
      'Extra': Icons.trending_up,
      'เงินออม': Icons.savings,
      'Savings': Icons.savings,
    };

    for (final entry in iconMap.entries) {
      if (categoryName.contains(entry.key)) {
        return entry.value;
      }
    }
    return Icons.more_horiz;
  }
}
