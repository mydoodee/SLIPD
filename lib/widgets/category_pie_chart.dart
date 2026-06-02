import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../utils/formatters.dart';

class CategoryPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const CategoryPieChart({super.key, required this.data});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Column(
          children: [
            Icon(Icons.pie_chart_outline, color: AppTheme.textMuted, size: 48),
            SizedBox(height: 12),
            Text(
              'ยังไม่มีข้อมูล / No data yet',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

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
          const Text(
            'หมวดหมู่รายจ่าย / Expense Categories',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Pie Chart
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                startDegreeOffset: -90,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildSections(),
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          ..._buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final total = widget.data.fold<double>(
      0,
      (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0),
    );

    return List.generate(widget.data.length, (index) {
      final item = widget.data[index];
      final value = (item['total'] as num?)?.toDouble() ?? 0;
      final percentage = total > 0 ? (value / total * 100) : 0.0;
      final isTouched = index == _touchedIndex;
      final color = AppTheme.chartColors[index % AppTheme.chartColors.length];

      return PieChartSectionData(
        color: color,
        value: value,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 55 : 45,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    });
  }

  List<Widget> _buildLegend() {
    final total = widget.data.fold<double>(
      0,
      (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0),
    );

    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final name = (item['category_name'] as String?) ?? 'อื่นๆ / Other';
      final value = (item['total'] as num?)?.toDouble() ?? 0;
      final percentage = total > 0 ? (value / total * 100) : 0.0;
      final color = AppTheme.chartColors[index % AppTheme.chartColors.length];

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: _touchedIndex == index ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: _touchedIndex == index ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '฿${Formatters.formatCurrency(value)}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }).toList();
  }
}
