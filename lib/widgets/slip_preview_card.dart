import 'dart:io';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/slip_parser.dart';
import '../utils/formatters.dart';

class SlipPreviewCard extends StatelessWidget {
  final SlipParseResult result;
  final String imagePath;

  const SlipPreviewCard({
    super.key,
    required this.result,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slip image preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.image_not_supported, color: AppTheme.textMuted, size: 48),
                ),
              ),
            ),
          ),

          // Parsed data
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: result.isSlip
                        ? AppTheme.incomeColor.withValues(alpha: 0.15)
                        : AppTheme.expenseColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.isSlip
                        ? '✓ ตรวจพบสลิป / Slip detected'
                        : '✗ ไม่ใช่สลิป / Not a slip',
                    style: TextStyle(
                      color: result.isSlip ? AppTheme.incomeColor : AppTheme.expenseColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (result.isSlip) ...[
                  // จำนวนเงิน
                  if (result.amount != null)
                    _dataRow(
                      Icons.payments_outlined,
                      'จำนวนเงิน / Amount',
                      '฿${Formatters.formatCurrency(result.amount!)}',
                      AppTheme.primaryGreen,
                    ),

                  // วันที่
                  if (result.date != null)
                    _dataRow(
                      Icons.calendar_today_outlined,
                      'วันที่ / Date',
                      Formatters.formatDateTime(result.date!),
                      AppTheme.balanceColor,
                    ),

                  // ธนาคาร
                  if (result.bankName != null)
                    _dataRow(
                      Icons.account_balance_outlined,
                      'ธนาคาร / Bank',
                      result.bankName!,
                      AppTheme.textPrimary,
                    ),

                  // ผู้โอน
                  if (result.sender != null)
                    _dataRow(
                      Icons.person_outline,
                      'ผู้โอน / Sender',
                      result.sender!,
                      AppTheme.textPrimary,
                    ),

                  // ผู้รับ
                  if (result.receiver != null)
                    _dataRow(
                      Icons.person_outlined,
                      'ผู้รับ / Receiver',
                      result.receiver!,
                      AppTheme.textPrimary,
                    ),

                  // เลขอ้างอิง
                  if (result.refNo != null)
                    _dataRow(
                      Icons.tag,
                      'เลขอ้างอิง / Ref No.',
                      result.refNo!,
                      AppTheme.textSecondary,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(IconData icon, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
