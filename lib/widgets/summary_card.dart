import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/formatters.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final LinearGradient gradient;
  final Color textColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.gradient,
    required this.textColor,
  });

  /// Card สำหรับรายรับ
  factory SummaryCard.income({Key? key, required double amount}) {
    return SummaryCard(
      key: key,
      title: 'รายรับ / Income',
      amount: amount,
      icon: Icons.arrow_downward_rounded,
      gradient: AppTheme.incomeGradient,
      textColor: AppTheme.incomeColor,
    );
  }

  /// Card สำหรับรายจ่าย
  factory SummaryCard.expense({Key? key, required double amount}) {
    return SummaryCard(
      key: key,
      title: 'รายจ่าย / Expense',
      amount: amount,
      icon: Icons.arrow_upward_rounded,
      gradient: AppTheme.expenseGradient,
      textColor: AppTheme.expenseColor,
    );
  }

  /// Card สำหรับคงเหลือ
  factory SummaryCard.balance({Key? key, required double amount}) {
    return SummaryCard(
      key: key,
      title: 'คงเหลือ / Balance',
      amount: amount,
      icon: Icons.account_balance_wallet_rounded,
      gradient: AppTheme.primaryGradient,
      textColor: AppTheme.balanceColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: amount),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '฿${Formatters.formatCurrency(value)}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
