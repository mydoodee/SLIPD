import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/ocr_service.dart';
import '../services/slip_parser.dart';
import '../services/category_classifier.dart';
import '../services/duplicate_checker.dart';

class DiscoveredSlip {
  final String assetId;
  final String imagePath;
  final SlipParseResult result;
  final TransactionModel prefillData;

  DiscoveredSlip({
    required this.assetId,
    required this.imagePath,
    required this.result,
    required this.prefillData,
  });
}

class GalleryScanResult {
  final bool permissionGranted;
  final List<DiscoveredSlip> discoveredSlips;
  final int totalScanned;
  final int newSlipsCount;

  GalleryScanResult({
    required this.permissionGranted,
    required this.discoveredSlips,
    this.totalScanned = 0,
    this.newSlipsCount = 0,
  });
}

class GalleryScannerService {
  final DatabaseHelper _db = DatabaseHelper();
  final OcrService _ocrService = OcrService();
  final DuplicateChecker _duplicateChecker = DuplicateChecker();

  Future<bool> checkAndRequestPermission() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    return state == PermissionState.authorized || state == PermissionState.limited;
  }

  /// สแกนคลังภาพย้อนหลังเพื่อค้นหาสลิปใหม่
  Future<GalleryScanResult> scanGallery({
    int limit = 100,
    Function(int current, int total)? onProgress,
  }) async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      return GalleryScanResult(permissionGranted: false, discoveredSlips: []);
    }

    // ดึงอัลบั้มรูปภาพทั้งหมด (ดึงเฉพาะรูปภาพ)
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) {
      return GalleryScanResult(permissionGranted: true, discoveredSlips: [], totalScanned: 0);
    }

    final AssetPathEntity mainAlbum = albums.first;
    
    // ดึงรูปภาพจำนวนจำกัดล่าสุด
    final List<AssetEntity> assets = await mainAlbum.getAssetListRange(
      start: 0,
      end: limit,
    );

    if (assets.isEmpty) {
      return GalleryScanResult(permissionGranted: true, discoveredSlips: [], totalScanned: 0);
    }

    final assetIds = assets.map((a) => a.id).toList();
    
    // เช็คในฐานข้อมูลว่ามีตัวไหนแสกนไปแล้วบ้าง
    final processedAssetIds = await _db.getProcessedAssetIds(assetIds);

    // กรองเอาเฉพาะรูปภาพใหม่ที่ยังไม่ได้สแกน
    final newAssets = assets.where((a) => !processedAssetIds.contains(a.id)).toList();
    
    if (newAssets.isEmpty) {
      return GalleryScanResult(
        permissionGranted: true,
        discoveredSlips: [],
        totalScanned: 0,
      );
    }

    // โหลดหมวดหมู่ทั้งหมดสำหรับเอามาอ้างอิง ID
    final List<CategoryModel> dbCategories = await _db.getCategories();

    int? findCategoryId(String? name) {
      if (name == null) return null;
      try {
        // ค้นหาหมวดหมู่ที่ชื่อมีความใกล้เคียง
        return dbCategories.firstWhere(
          (c) => c.name.toLowerCase().contains(name.toLowerCase()) || 
                 name.toLowerCase().contains(c.name.toLowerCase())
        ).id;
      } catch (_) {
        return null;
      }
    }

    final List<DiscoveredSlip> discovered = [];

    for (int i = 0; i < newAssets.length; i++) {
      final asset = newAssets[i];
      onProgress?.call(i + 1, newAssets.length);

      try {
        final File? file = await asset.file;
        if (file == null) {
          // หากดึงไฟล์ไม่ได้ ให้บันทึกว่าตรวจสอบแล้วและไม่ใช่สลิปเพื่อข้ามในอนาคต
          await _db.markAssetProcessed(asset.id, false);
          continue;
        }

        // 1. ทำ OCR อ่านข้อความจากรูปภาพ
        final rawText = await _ocrService.extractText(file.path);
        if (rawText == null || rawText.isEmpty) {
          await _db.markAssetProcessed(asset.id, false);
          continue;
        }

        // 2. วิเคราะห์ว่าเป็นสลิปหรือไม่
        final parseResult = SlipParser.parse(rawText);
        
        if (parseResult.isSlip) {
          // บันทึกในระบบว่ารูปภาพนี้สแกนและเป็นสลิปแล้ว
          await _db.markAssetProcessed(asset.id, true);

          // 3. ตรวจสอบรายการซ้ำในตารางธุรกรรม (เทียบ hash)
          final dupCheck = await _duplicateChecker.check(
            date: parseResult.date ?? DateTime.now(),
            amount: parseResult.amount ?? 0.0,
            refNo: parseResult.refNo,
          );

          if (!dupCheck.isDuplicate) {
            // คัดกรองหมวดหมู่แนะนำตามคำสำคัญ
            final suggestedCategory = CategoryClassifier.classify(
              parseResult.receiver,
              null,
              parseResult.sender,
            );
            final suggestedType = CategoryClassifier.suggestType(
              '${parseResult.sender ?? ''} ${parseResult.receiver ?? ''}',
            );

            final prefill = TransactionModel(
              amount: parseResult.amount ?? 0.0,
              type: suggestedType,
              bankName: parseResult.bankName,
              sender: parseResult.sender,
              receiver: parseResult.receiver,
              refNo: parseResult.refNo,
              imagePath: file.path,
              transactionDate: parseResult.date ?? DateTime.now(),
              note: parseResult.receiver,
              categoryId: findCategoryId(suggestedCategory),
              categoryName: suggestedCategory,
            );

            discovered.add(DiscoveredSlip(
              assetId: asset.id,
              imagePath: file.path,
              result: parseResult,
              prefillData: prefill,
            ));
          }
        } else {
          // บันทึกในระบบว่ารูปภาพนี้สแกนและไม่ใช่สลิป
          await _db.markAssetProcessed(asset.id, false);
        }
      } catch (e) {
        // กรณีเกิดข้อผิดพลาดในการสแกนไฟล์ใดไฟล์หนึ่ง ให้บันทึกข้ามไปก่อนเพื่อไม่ให้ระบบค้าง
        await _db.markAssetProcessed(asset.id, false);
      }
    }

    return GalleryScanResult(
      permissionGranted: true,
      discoveredSlips: discovered,
      totalScanned: newAssets.length,
      newSlipsCount: discovered.length,
    );
  }
}
