import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/monthly_chart.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/transaction_tile.dart';
import 'scan_slip_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _fadeController.forward();
    });
  }

  void _loadData() {
    context.read<DashboardProvider>().loadDashboard();
    context.read<TransactionProvider>().loadTransactions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          color: AppTheme.primaryGreen,
          backgroundColor: AppTheme.cardBg,
          onRefresh: () async => _loadData(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.scaffoldBg,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'slipD',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),

                    // วันนี้ / Today header
                    _sectionHeader('วันนี้ / Today'),
                    const SizedBox(height: 12),

                    // Summary cards - Today
                    Consumer<DashboardProvider>(
                      builder: (context, provider, _) {
                        final s = provider.todaySummary;
                        return Column(
                          children: [
                            SummaryCard.income(amount: s['income'] ?? 0),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: SummaryCard.expense(amount: s['expense'] ?? 0),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SummaryCard.balance(amount: s['balance'] ?? 0),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // เดือนนี้ / This Month header
                    _sectionHeader('เดือนนี้ / This Month'),
                    const SizedBox(height: 8),
                    Consumer<DashboardProvider>(
                      builder: (context, provider, _) {
                        final s = provider.monthSummary;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGreen.withValues(alpha: 0.08),
                                AppTheme.cardBg,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Flexible(child: _monthStatItem('รายรับ', s['income'] ?? 0, AppTheme.incomeColor)),
                              Container(width: 1, height: 40, color: AppTheme.borderColor),
                              Flexible(child: _monthStatItem('รายจ่าย', s['expense'] ?? 0, AppTheme.expenseColor)),
                              Container(width: 1, height: 40, color: AppTheme.borderColor),
                              Flexible(child: _monthStatItem('คงเหลือ', s['balance'] ?? 0, AppTheme.balanceColor)),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Monthly Chart
                    Consumer<DashboardProvider>(
                      builder: (context, provider, _) {
                        return MonthlyChart(
                          data: provider.monthlySummary,
                          selectedYear: provider.selectedYear,
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Category Pie Chart
                    Consumer<DashboardProvider>(
                      builder: (context, provider, _) {
                        return CategoryPieChart(data: provider.categorySummary);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quick Auto-Scan Card
                    _buildQuickScanCard(),
                    const SizedBox(height: 24),

                    // Recent Transactions
                    _sectionHeader('รายการล่าสุด / Recent'),
                    const SizedBox(height: 12),

                    Consumer<TransactionProvider>(
                      builder: (context, provider, _) {
                        if (provider.transactions.isEmpty) {
                          return _emptyState();
                        }

                        final recent = provider.transactions.take(5).toList();
                        return Column(
                          children: recent.map((txn) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TransactionTile(
                                transaction: txn,
                                onDelete: () {
                                  provider.deleteTransaction(txn.id!);
                                  context.read<DashboardProvider>().loadDashboard();
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 100), // bottom padding for FAB
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _monthStatItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '฿${_shortAmount(amount)}',
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _shortAmount(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildQuickScanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.1),
            AppTheme.cardBg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bolt,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ตรวจพบสลิปใหม่ในเครื่อง?',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'สแกนหารายการโอนเงินล่าสุดอัตโนมัติ',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'สแกนคลังภาพของคุณแบบออฟไลน์ 100% เพื่อตรวจจับสลิปโอนเงินใหม่ที่ยังไม่ได้บันทึก',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanSlipScreen(autoStartScan: true),
                  ),
                ).then((_) {
                  _loadData();
                });
              },
              icon: const Icon(Icons.search, size: 16),
              label: const Text('เริ่มค้นหาสลิป / Start Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: const Color(0xFF003300),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: AppTheme.textMuted, size: 56),
          SizedBox(height: 16),
          Text(
            'ยังไม่มีรายการ / No transactions yet',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'กด + เพื่อเพิ่มรายการหรือสแกนสลิป\nTap + to add or scan a slip',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
