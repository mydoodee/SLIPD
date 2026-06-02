/// ผลลัพธ์จากการ parse สลิปโอนเงิน
/// Result from parsing a bank transfer slip
class SlipParseResult {
  final DateTime? date;
  final double? amount;
  final String? bankName;
  final String? sender;
  final String? receiver;
  final String? refNo;
  final bool isSlip;
  final String rawText;

  SlipParseResult({
    this.date,
    this.amount,
    this.bankName,
    this.sender,
    this.receiver,
    this.refNo,
    required this.isSlip,
    required this.rawText,
  });
}

class SlipParser {
  // คำสำคัญสำหรับตรวจสอบว่าเป็นสลิปหรือไม่ (รวมชื่อแอป/ธนาคารในไทยและคำภาษาอังกฤษทั่วไป)
  static const _slipKeywords = [
    // ทั่วไป (General)
    'โอนเงิน', 'transfer', 'reference', 'ref', 'บาท', 'baht', 'thb',
    'transaction', 'promptpay', 'qr payment', 'พร้อมเพย์', 'เลขอ้างอิง',
    'สำเร็จ', 'successful', 'จำนวนเงิน', 'amount', 'ผู้โอน', 'ผู้รับ',
    'จาก', 'ไปยัง', 'from', 'to', 'ค่าธรรมเนียม', 'fee',
    // ชื่อแอป/ธนาคารในสลิป (Apps/Banks)
    'k plus', 'kplus', 'kbank', 'kasikorn', 'scb', 'siam commercial',
    'krungthai', 'ktb', 'next', 'bualuang', 'bangkok bank', 'mmo',
    'gsb', 'ออมสิน', 'krungsri', 'bay', 'ttb', 'tmb', 'thanachart',
    'tisco', 'kkp', 'kiatnakin', 'baac', 'ธ.ก.ส', 'cimb', 'uob',
  ];

  // ชื่อธนาคารที่รองรับ
  static const _bankPatterns = {
    'กสิกรไทย / KBank': ['กสิกร', 'kbank', 'kasikorn', 'k bank', 'k-bank', 'k plus', 'kplus', 'k-plus'],
    'กรุงไทย / KTB': ['กรุงไทย', 'ktb', 'krungthai', 'krung thai', 'next'],
    'ไทยพาณิชย์ / SCB': ['ไทยพาณิชย์', 'scb', 'siam commercial', 'scbeasy', 'scb easy'],
    'กรุงเทพ / BBL': ['กรุงเทพ', 'bbl', 'bangkok bank', 'bualuang', 'mualuang'],
    'ออมสิน / GSB': ['ออมสิน', 'gsb', 'government savings'],
    'กรุงศรี / BAY': ['กรุงศรี', 'bay', 'krungsri', 'ayudhya'],
    'ทีทีบี / TTB': ['ttb', 'ทีทีบี', 'tmb', 'thanachart', 'ทีเอ็มบี', 'ธนชาต'],
    'ทิสโก้ / TISCO': ['tisco', 'ทิสโก้'],
    'เกียรตินาคิน / KKP': ['เกียรตินาคิน', 'kkp', 'kiatnakin'],
    'ธ.ก.ส. / BAAC': ['ธ.ก.ส', 'baac', 'เพื่อการเกษตร'],
  };

  /// ตรวจสอบว่า text เป็นสลิปหรือไม่
  /// Check if the text looks like a bank slip
  static bool isSlipText(String text) {
    final lowerText = text.toLowerCase();
    
    // 1. ตรวจสอบคำสำคัญทั่วไปและชื่อธนาคาร
    int matchCount = 0;
    for (final keyword in _slipKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        matchCount++;
      }
    }

    // 2. ตรวจสอบว่ามีตัวเลขยอดเงิน (ทศนิยม 2 ตำแหน่ง) หรือไม่
    final hasDecimal = RegExp(r'\b\d+[\.,]\d{2}\b').hasMatch(lowerText);
    
    // 3. ตรวจสอบว่ามีเลขบัญชีหรือเลขอ้างอิงที่เป็นตัวเลขยาวๆ หรือไม่ (เลขอ้างอิงโอนเงิน มักจะยาว 10 หลักขึ้นไป)
    final hasLongNum = RegExp(r'\b\d{10,}\b').hasMatch(lowerText);

    // เงื่อนไขการตรวจจับว่าเป็นสลิป:
    // - มีคำสำคัญ/ชื่อธนาคาร 3 คำขึ้นไป
    // - หรือ มีคำสำคัญ 2 คำขึ้นไป + มียอดเงินทศนิยม
    // - หรือ มีคำสำคัญอย่างน้อย 1 คำ + มียอดเงินทศนิยม + มีตัวเลขยาว (เลขอ้างอิง/บัญชี)
    if (matchCount >= 3) return true;
    if (matchCount >= 2 && hasDecimal) return true;
    if (matchCount >= 1 && hasDecimal && hasLongNum) return true;

    return false;
  }

  /// Parse ข้อความจากสลิปเป็น SlipParseResult
  /// Parse raw OCR text into structured slip data
  static SlipParseResult parse(String rawText) {
    if (!isSlipText(rawText)) {
      return SlipParseResult(isSlip: false, rawText: rawText);
    }

    return SlipParseResult(
      date: _parseDate(rawText),
      amount: _parseAmount(rawText),
      bankName: _parseBank(rawText),
      sender: _parseSender(rawText),
      receiver: _parseReceiver(rawText),
      refNo: _parseRefNo(rawText),
      isSlip: true,
      rawText: rawText,
    );
  }

  /// ดึงวันที่จากสลิป
  static DateTime? _parseDate(String text) {
    // Pattern: DD/MM/YYYY หรือ DD-MM-YYYY หรือ DD/MM/YY
    final datePatterns = [
      RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})'),
      RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2})\b'),
    ];

    // Pattern สำหรับเวลา
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?');

    DateTime? parsedDate;

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        int day = int.tryParse(match.group(1)!) ?? 0;
        int month = int.tryParse(match.group(2)!) ?? 0;
        int year = int.tryParse(match.group(3)!) ?? 0;

        // แก้ปี 2 หลัก
        if (year < 100) year += 2000;
        // แก้ปี พ.ศ. เป็น ค.ศ.
        if (year > 2500) year -= 543;

        if (day > 0 && day <= 31 && month > 0 && month <= 12) {
          parsedDate = DateTime(year, month, day);
          break;
        }
      }
    }

    // เพิ่มเวลาถ้ามี
    if (parsedDate != null) {
      final timeMatch = timePattern.firstMatch(text);
      if (timeMatch != null) {
        final hour = int.tryParse(timeMatch.group(1)!) ?? 0;
        final minute = int.tryParse(timeMatch.group(2)!) ?? 0;
        final second = int.tryParse(timeMatch.group(3) ?? '0') ?? 0;
        parsedDate = DateTime(
          parsedDate.year, parsedDate.month, parsedDate.day,
          hour, minute, second,
        );
      }
    }

    return parsedDate;
  }

  /// ดึงจำนวนเงินจากสลิป
  static double? _parseAmount(String text) {
    // Pattern: จำนวนเงิน หรือ amount ตามด้วยตัวเลข
    final amountPatterns = [
      // "จำนวนเงิน 1,500.00 บาท" หรือ "Amount 1,500.00 THB"
      RegExp(r'(?:จำนวน(?:เงิน)?|amount|total|ยอดเงิน|ยอดโอน|ยอดเงินโอน)[:\s]*([\d,]+\.?\d*)', caseSensitive: false),
      // "1,500.00 บาท" หรือ "1,500.00 THB" หรือ "1,500.00 Baht" (รวมคำอ่านเพี้ยนจากการสแกนแบบ Latin เช่น un, um, บ.)
      RegExp(r'([\d,]+\.\d{2})\s*(?:บาท|thb|baht|un|um|บ\.)', caseSensitive: false),
      // ตัวเลขขนาดใหญ่ที่มีทศนิยม 2 ตำแหน่ง
      RegExp(r'\b([\d,]+\.\d{2})\b'),
    ];

    for (final pattern in amountPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0 && amount < 10000000) {
            return amount;
          }
        }
      }
    }

    return null;
  }

  /// ตรวจหาชื่อธนาคาร
  static String? _parseBank(String text) {
    final lowerText = text.toLowerCase();

    for (final entry in _bankPatterns.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }

    return null;
  }

  /// ดึงชื่อผู้โอน
  static String? _parseSender(String text) {
    final patterns = [
      RegExp(r'(?:จาก|from|ผู้โอน|ชื่อผู้โอน)[:\s]*(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'(?:ผู้ส่ง|sender)[:\s]*(.+?)(?:\n|$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty && name.length < 100) {
          return name;
        }
      }
    }

    return null;
  }

  /// ดึงชื่อผู้รับ
  static String? _parseReceiver(String text) {
    final patterns = [
      RegExp(r'(?:ไปยัง|ถึง|to|ผู้รับ|ชื่อผู้รับ)[:\s]*(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'(?:receiver|ปลายทาง)[:\s]*(.+?)(?:\n|$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty && name.length < 100) {
          return name;
        }
      }
    }

    return null;
  }

  /// ดึงเลขอ้างอิง
  static String? _parseRefNo(String text) {
    final patterns = [
      RegExp(r'(?:ref(?:erence)?(?:\s*(?:no|number|#))?|เลขอ้างอิง|รหัสอ้างอิง|เลขที่รายการ)[:\s]*([A-Za-z0-9]+)', caseSensitive: false),
      RegExp(r'(?:transaction\s*(?:id|no))[:\s]*([A-Za-z0-9]+)', caseSensitive: false),
      // Fallback: ดึงตัวเลขต่อกันยาวๆ 10-20 หลัก ที่มักจะเป็นเลขที่อ้างอิงหรือเลขที่ธุรกรรม
      RegExp(r'\b(\d{10,20})\b'),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final ref = match.group(1)?.trim();
        if (ref != null && ref.isNotEmpty && ref.length >= 10) {
          return ref;
        }
      }
    }

    return null;
  }
}
