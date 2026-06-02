import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import '../providers/dashboard_provider.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchController = TextEditingController();
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการ / Transactions'),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.scaffoldBg,
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ค้นหา... / Search...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
                const SizedBox(height: 10),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('ทั้งหมด / All', null),
                      const SizedBox(width: 8),
                      _filterChip('รายรับ / Income', 'income'),
                      const SizedBox(width: 8),
                      _filterChip('รายจ่าย / Expense', 'expense'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  );
                }

                if (provider.transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, color: AppTheme.textMuted, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty || _selectedType != null
                              ? 'ไม่พบรายการ / No results found'
                              : 'ยังไม่มีรายการ / No transactions yet',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primaryGreen,
                  backgroundColor: AppTheme.cardBg,
                  onRefresh: () async {
                    _applyFilters();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.transactions.length,
                    itemBuilder: (context, index) {
                      final txn = provider.transactions[index];

                      // Date separator
                      Widget? separator;
                      if (index == 0 ||
                          _isDifferentDay(
                            provider.transactions[index - 1].transactionDate,
                            txn.transactionDate,
                          )) {
                        separator = Padding(
                          padding: EdgeInsets.only(
                            top: index == 0 ? 0 : 16,
                            bottom: 8,
                          ),
                          child: Text(
                            _formatDateGroup(txn.transactionDate),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ?separator,
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TransactionTile(
                              transaction: txn,
                              onDelete: () {
                                provider.deleteTransaction(txn.id!);
                                context.read<DashboardProvider>().loadDashboard();
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = type);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
              : AppTheme.cardBgLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    context.read<TransactionProvider>().setFilter(
          type: _selectedType,
          search: _searchController.text.isEmpty ? null : _searchController.text,
        );
  }

  bool _isDifferentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return '📅 วันนี้ / Today';
    if (diff == 1) return '📅 เมื่อวาน / Yesterday';

    return '📅 ${date.day}/${date.month}/${date.year}';
  }
}
