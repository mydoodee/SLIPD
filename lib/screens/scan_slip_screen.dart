import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../models/transaction.dart';
import '../services/ocr_service.dart';
import '../services/slip_parser.dart';
import '../services/category_classifier.dart';
import '../widgets/slip_preview_card.dart';
import 'add_transaction_screen.dart';
import '../services/gallery_scanner_service.dart';
import '../database/database_helper.dart';
import '../utils/formatters.dart';

class ScanSlipScreen extends StatefulWidget {
  final bool autoStartScan;
  const ScanSlipScreen({super.key, this.autoStartScan = false});

  @override
  State<ScanSlipScreen> createState() => _ScanSlipScreenState();
}

class _ScanSlipScreenState extends State<ScanSlipScreen>
    with SingleTickerProviderStateMixin {
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();
  final GalleryScannerService _galleryScanner = GalleryScannerService();

  bool _isProcessing = false;
  SlipParseResult? _parseResult;
  String? _selectedImagePath;
  String? _errorMessage;

  bool _isScanningGallery = false;
  String _scanProgressText = '';
  List<DiscoveredSlip> _discoveredSlips = [];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.autoStartScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startGalleryScan();
      });
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกนสลิป / Scan Slip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Scan button area
            if (_parseResult == null && !_isProcessing) _buildScanArea(),

            // Processing indicator
            if (_isProcessing) _buildProcessing(),

            // Error message
            if (_errorMessage != null) _buildError(),

            // Parsed result
            if (_parseResult != null && _selectedImagePath != null) ...[
              SlipPreviewCard(
                result: _parseResult!,
                imagePath: _selectedImagePath!,
              ),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanArea() {
    return Column(
      children: [
        const SizedBox(height: 40),

        // Main scan button
        GestureDetector(
          onTap: _pickImage,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.15 + (_pulseController.value * 0.1)),
                      AppTheme.primaryGreen.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'สแกนสลิปโอนเงิน',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Scan Transfer Slip',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'เลือกรูปสลิปจากแกลเลอรีเพื่ออ่านข้อมูลอัตโนมัติ\nSelect a slip image from gallery for auto-reading',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        _buildAutoScanCard(),
        _buildDiscoveredSlipsList(),
        const SizedBox(height: 24),

        // Alternative options
        Row(
          children: [
            Expanded(
              child: _optionButton(
                Icons.photo_library_outlined,
                'แกลเลอรี\nGallery',
                _pickImage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _optionButton(
                Icons.camera_alt_outlined,
                'กล้อง\nCamera',
                _takePhoto,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Supported banks
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ธนาคารที่รองรับ / Supported Banks',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _bankChip('กสิกร'),
                  _bankChip('กรุงไทย'),
                  _bankChip('SCB'),
                  _bankChip('กรุงเทพ'),
                  _bankChip('ออมสิน'),
                  _bankChip('กรุงศรี'),
                  _bankChip('TTB'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _optionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.cardBgLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      ),
    );
  }

  Widget _buildProcessing() {
    return Column(
      children: [
        const SizedBox(height: 80),
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 3,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'กำลังอ่านสลิป...',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Processing slip...',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.expenseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.expenseColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.expenseColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Scan again
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetScan,
            icon: const Icon(Icons.refresh),
            label: const Text('สแกนใหม่\nRe-scan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Save / Edit
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _parseResult!.isSlip ? _proceedToSave : null,
            icon: const Icon(Icons.check),
            label: const Text('บันทึก / Save'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        _processImage(image.path);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถเลือกรูปได้ / Cannot select image\n$e';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        _processImage(image.path);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถถ่ายรูปได้ / Cannot take photo\n$e';
      });
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _parseResult = null;
      _selectedImagePath = imagePath;
    });

    try {
      // ตรวจสอบว่ารองรับ OCR หรือไม่
      if (!_ocrService.isSupported) {
        // Fallback: ให้ user กรอกเอง
        setState(() {
          _isProcessing = false;
          _parseResult = SlipParseResult(isSlip: false, rawText: '');
          _errorMessage =
              'OCR ไม่รองรับบน platform นี้\nOCR is not supported on this platform.\n\nกรุณากรอกข้อมูลด้วยตนเอง / Please enter data manually.';
        });
        return;
      }

      // OCR
      final rawText = await _ocrService.extractText(imagePath);

      if (rawText == null || rawText.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'ไม่สามารถอ่านข้อความจากรูปได้\nCannot extract text from image';
        });
        return;
      }

      // Parse
      final result = SlipParser.parse(rawText);

      setState(() {
        _isProcessing = false;
        _parseResult = result;
        if (!result.isSlip) {
          _errorMessage =
              'ไม่พบข้อมูลสลิปในรูปภาพ / No slip data found in image\n\nข้อความที่อ่านได้:\n${rawText.substring(0, rawText.length > 200 ? 200 : rawText.length)}...';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  void _resetScan() {
    setState(() {
      _parseResult = null;
      _selectedImagePath = null;
      _errorMessage = null;
    });
  }

  void _proceedToSave() {
    if (_parseResult == null || !_parseResult!.isSlip) return;

    final r = _parseResult!;

    // Auto classify
    final suggestedCategory = CategoryClassifier.classify(
      r.receiver,
      null,
      r.sender,
    );
    final suggestedType = CategoryClassifier.suggestType(
      '${r.sender ?? ''} ${r.receiver ?? ''}',
    );

    final prefillData = TransactionModel(
      amount: r.amount ?? 0,
      type: suggestedType,
      bankName: r.bankName,
      sender: r.sender,
      receiver: r.receiver,
      refNo: r.refNo,
      imagePath: _selectedImagePath,
      transactionDate: r.date ?? DateTime.now(),
      note: r.receiver,
      categoryName: suggestedCategory,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(prefillData: prefillData),
      ),
    ).then((_) => _resetScan());
  }

  Widget _buildAutoScanCard() {
    if (_isScanningGallery) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _scanProgressText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            const Text(
              'ระบบกำลังค้นหาและวิเคราะห์สลิปในคลังภาพของคุณ...',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สแกนรูปภาพในเครื่องอัตโนมัติ',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Auto-Scan Gallery',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'ค้นหาและนำเข้าสลิปใหม่ล่าสุดจากคลังภาพของคุณได้ทันทีโดยไม่ต้องอัปโหลดทีละรูป',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _startGalleryScan,
              icon: const Icon(Icons.search, size: 18, color: Color(0xFF003300)),
              label: const Text('ค้นหาสลิปใหม่ในเครื่อง / Start Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: const Color(0xFF003300),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _resetScanHistory,
              icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppTheme.textMuted),
              label: const Text(
                'รีเซ็ตประวัติการสแกน / Reset Scan History',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveredSlipsList() {
    if (_discoveredSlips.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'พบสลิปใหม่ในเครื่อง (${_discoveredSlips.length})',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _discoveredSlips.clear()),
              child: const Text('ล้าง / Clear', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _discoveredSlips.length,
          itemBuilder: (context, index) {
            final slip = _discoveredSlips[index];
            final prefill = slip.prefillData;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Image.file(
                        File(slip.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.cardBgLight,
                          child: const Icon(Icons.image_not_supported, size: 20, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prefill.receiver ?? prefill.bankName ?? 'สลิปโอนเงิน / Slip',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '฿${Formatters.formatCurrency(prefill.amount)}',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              Formatters.formatDate(prefill.transactionDate),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => _importDiscoveredSlip(slip, index),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                        child: const Text(
                          'บันทึก',
                          style: TextStyle(fontSize: 12, color: Color(0xFF003300), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => _ignoreDiscoveredSlip(slip.assetId, index),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'ข้าม',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _startGalleryScan() async {
    setState(() {
      _isScanningGallery = true;
      _scanProgressText = 'กำลังขอสิทธิ์เข้าถึงคลังภาพ...';
      _discoveredSlips.clear();
      _errorMessage = null;
    });

    try {
      final result = await _galleryScanner.scanGallery(
        limit: 300,
        onProgress: (current, total) {
          setState(() {
            _scanProgressText = 'กำลังสแกนวิเคราะห์รูปที่ $current / $total รูป...';
          });
        },
      );

      setState(() {
        _isScanningGallery = false;
      });

      if (!result.permissionGranted) {
        setState(() {
          _errorMessage = 'กรุณาอนุญาตสิทธิ์การเข้าถึงรูปภาพในตั้งค่าเพื่อใช้งานฟีเจอร์นี้\nPlease grant gallery access in settings.';
        });
        return;
      }

      setState(() {
        _discoveredSlips = result.discoveredSlips;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.newSlipsCount > 0
                        ? 'สแกนคลังภาพเสร็จสิ้น! พบสลิปใหม่ ${result.newSlipsCount} รายการ'
                        : 'สแกนคลังภาพเสร็จสิ้น! ไม่พบสลิปใหม่เพิ่มเติม',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.cardBgLight,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanningGallery = false;
        _errorMessage = 'เกิดข้อผิดพลาดระหว่างสแกน: $e';
      });
    }
  }

  void _importDiscoveredSlip(DiscoveredSlip slip, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(prefillData: slip.prefillData),
      ),
    ).then((saved) {
      // หากผู้ใช้บันทึกสำเร็จ หน้าจอจะคืนค่าเป็น true หรือ provider จะรีเฟรชข้อมูลเอง
      // ให้เอาสลิปนี้ออกจากลิสต์ที่พรีวิวอยู่
      setState(() {
        _discoveredSlips.removeAt(index);
      });
    });
  }

  Future<void> _ignoreDiscoveredSlip(String assetId, int index) async {
    final DatabaseHelper db = DatabaseHelper();
    // ทำเครื่องหมายว่าเป็น 0 (ไม่ใช่สลิป) เพื่อไม่ให้นำมาสแกนซ้ำอีกในอนาคต
    await db.markAssetProcessed(assetId, false);
    setState(() {
      _discoveredSlips.removeAt(index);
    });
  }

  Future<void> _resetScanHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text(
          'ยืนยันรีเซ็ตประวัติ / Confirm Reset',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'ระบบจะลบความจำภาพเดิมที่เคยสแกน เพื่อให้สามารถค้นหาและสแกนคลังรูปภาพทั้งหมดใหม่อีกครั้งได้\n\nDo you want to reset scan history to allow re-scanning all photos?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก / Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ยืนยัน / Reset',
              style: TextStyle(color: AppTheme.expenseColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = DatabaseHelper();
      await db.clearProcessedAssets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                SizedBox(width: 10),
                Expanded(
                  child: Text('รีเซ็ตประวัติสแกนแล้ว! สามารถสแกนคลังภาพทั้งหมดใหม่ได้ทันที'),
                ),
              ],
            ),
            backgroundColor: AppTheme.cardBgLight,
          ),
        );
      }
    }
  }
}
