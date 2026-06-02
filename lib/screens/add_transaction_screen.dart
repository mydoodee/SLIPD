import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/transaction_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/formatters.dart';

class AddTransactionScreen extends StatefulWidget {
  /// Pre-filled data from OCR scan
  final TransactionModel? prefillData;

  const AddTransactionScreen({super.key, this.prefillData});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill จาก OCR
    if (widget.prefillData != null) {
      final data = widget.prefillData!;
      _amountController.text = data.amount > 0 ? data.amount.toString() : '';
      _noteController.text = data.note ?? data.receiver ?? '';
      _type = data.type;
      _selectedDate = data.transactionDate;
      _selectedTime = TimeOfDay.fromDateTime(data.transactionDate);
      _selectedCategoryId = data.categoryId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadCategories(type: _type).then((_) {
        if (mounted && widget.prefillData?.categoryName != null && _selectedCategoryId == null) {
          final id = context.read<TransactionProvider>().findCategoryIdByName(widget.prefillData!.categoryName);
          if (id != null) {
            setState(() {
              _selectedCategoryId = id;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.prefillData != null
              ? 'ยืนยันรายการ / Confirm'
              : 'เพิ่มรายการ / Add',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle Income / Expense
              _buildTypeToggle(),
              const SizedBox(height: 24),

              // Amount
              _buildLabel('จำนวนเงิน / Amount'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: '฿ ',
                  prefixStyle: TextStyle(
                    color: _type == 'income' ? AppTheme.incomeColor : AppTheme.expenseColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: '0.00',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกจำนวนเงิน / Please enter amount';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return 'จำนวนเงินไม่ถูกต้อง / Invalid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Grid
              _buildLabel('หมวดหมู่ / Category'),
              const SizedBox(height: 8),
              _buildCategoryGrid(),
              const SizedBox(height: 20),

              // Note
              _buildLabel('หมายเหตุ / Note'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: AppTheme.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'เพิ่มรายละเอียด... / Add details...',
                ),
              ),
              const SizedBox(height: 20),

              // Date & Time
              _buildLabel('วันที่และเวลา / Date & Time'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateButton(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeButton(),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'บันทึก / Save',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003300),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardBgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          _typeButton('expense', 'รายจ่าย / Expense', AppTheme.expenseColor),
          _typeButton('income', 'รายรับ / Income', AppTheme.incomeColor),
        ],
      ),
    );
  }

  Widget _typeButton(String type, String label, Color color) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _type = type);
          context.read<TransactionProvider>().loadCategories(type: type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final categories = provider.categories
            .where((c) => c.type == _type || c.type == 'both')
            .toList();

        if (categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'กำลังโหลด... / Loading...',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((cat) => _categoryChip(cat)).toList(),
        );
      },
    );
  }

  Widget _categoryChip(CategoryModel category) {
    final isSelected = _selectedCategoryId == category.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
              : AppTheme.cardBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.iconData,
              size: 18,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              category.name.split(' / ').first, // แสดงแค่ชื่อไทย
              style: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              Formatters.formatDate(_selectedDate),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_outlined, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryGreen,
              surface: AppTheme.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryGreen,
              surface: AppTheme.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    final date = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final transaction = TransactionModel(
      amount: amount,
      type: _type,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      categoryId: _selectedCategoryId,
      transactionDate: date,
      bankName: widget.prefillData?.bankName,
      sender: widget.prefillData?.sender,
      receiver: widget.prefillData?.receiver,
      refNo: widget.prefillData?.refNo,
      imagePath: widget.prefillData?.imagePath,
    );

    final provider = context.read<TransactionProvider>();
    final result = await provider.addTransaction(transaction);

    if (mounted) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: result.success ? AppTheme.incomeColor : AppTheme.expenseColor,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor: AppTheme.cardBgLight,
        ),
      );

      if (result.success) {
        context.read<DashboardProvider>().loadDashboard();
        Navigator.pop(context);
      }
    }
  }
}
