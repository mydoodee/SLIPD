import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../utils/formatters.dart';

class MonthlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final int selectedYear;

  const MonthlyChart({
    super.key,
    required this.data,
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'สรุปรายเดือน / Monthly',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$selectedYear',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Legend
          Row(
            children: [
              _legendDot(AppTheme.incomeColor, 'รายรับ'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.expenseColor, 'รายจ่าย'),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month = AppConstants.thaiMonths[group.x];
                      final type = rodIndex == 0 ? 'รายรับ' : 'รายจ่าย';
                      return BarTooltipItem(
                        '$month\n$type: ฿${Formatters.formatCurrency(rod.toY)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < 12) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              AppConstants.engMonths[value.toInt()],
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxY() / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.borderColor,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(12, (index) {
      final monthData = data.length > index ? data[index] : {'income': 0.0, 'expense': 0.0};
      final income = (monthData['income'] as num?)?.toDouble() ?? 0;
      final expense = (monthData['expense'] as num?)?.toDouble() ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: income,
            color: AppTheme.incomeColor,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: expense,
            color: AppTheme.expenseColor,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  double _getMaxY() {
    double max = 1000;
    for (final d in data) {
      final income = (d['income'] as num?)?.toDouble() ?? 0;
      final expense = (d['expense'] as num?)?.toDouble() ?? 0;
      if (income > max) max = income;
      if (expense > max) max = expense;
    }
    return max * 1.2;
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}
