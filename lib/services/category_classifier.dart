/// Auto categorization ตามคำสำคัญที่พบในข้อมูลสลิป
/// Keyword-based automatic category classification
class CategoryClassifier {
  // Mapping: keyword → category name (ตรงกับ seed_data.dart)
  static const Map<String, List<String>> _keywordMap = {
    'อาหาร / Food': [
      'ร้านอาหาร', 'อาหาร', 'food', 'restaurant', 'cafe', 'กาแฟ', 'coffee',
      'mcdonald', 'kfc', 'pizza', 'starbucks', 'ลาบ', 'ส้มตำ', 'ก๋วยเตี๋ยว',
      'ข้าวมันไก่', 'swensen', 'sizzler', 'mk', 'เอ็มเค', 'bar-b-q',
      'yayoi', 'bonchon', 'ชาบู', 'shabu', 'sushi', 'ซูชิ',
      'foodpanda', 'grab food', 'lineman', 'robinhood',
    ],
    'ค่าเดินทาง / Transport': [
      'grab', 'bolt', 'taxi', 'แท็กซี่', 'bts', 'mrt', 'airport link',
      'bus', 'รถเมล์', 'ค่ารถ', 'ค่าเดินทาง', 'transport',
      'motorcycle', 'วิน', 'toll', 'ทางด่วน', 'expressway',
    ],
    'ช้อปปิ้ง / Shopping': [
      'shopee', 'lazada', 'amazon', 'central', 'เซ็นทรัล', 'robinson',
      'big c', 'บิ๊กซี', 'tesco', 'เทสโก้', 'lotus', 'โลตัส', 'makro',
      'แม็คโคร', 'tops', 'ท็อปส์', 'uniqlo', 'h&m', 'zara', 'mall',
    ],
    'ค่าน้ำมัน / Fuel': [
      'ptt', 'ปตท', 'shell', 'เชลล์', 'bangchak', 'บางจาก',
      'esso', 'เอสโซ่', 'caltex', 'คาลเท็กซ์', 'susco', 'น้ำมัน', 'fuel',
      'gas', 'ปั๊ม', 'ev', 'ชาร์จ',
    ],
    'บิลค่าใช้จ่าย / Bills': [
      'ค่าน้ำ', 'ค่าไฟ', 'ค่าโทรศัพท์', 'ค่าเน็ต', 'ค่าประกัน',
      'insurance', 'internet', 'true', 'ais', 'dtac', '3bb',
      'pea', 'mea', 'กฟน', 'กฟภ', 'ประปา', 'water', 'electric',
      'bill', 'utility',
    ],
    'ที่อยู่อาศัย / Housing': [
      'ค่าเช่า', 'rent', 'คอนโด', 'condo', 'หอพัก', 'apartment',
      'ผ่อนบ้าน', 'mortgage', 'house', 'บ้าน',
    ],
    'การศึกษา / Education': [
      'ค่าเทอม', 'tuition', 'school', 'โรงเรียน', 'มหาวิทยาลัย',
      'university', 'course', 'udemy', 'skillshare', 'coursera',
    ],
    'สุขภาพ / Health': [
      'โรงพยาบาล', 'hospital', 'คลินิก', 'clinic', 'ยา', 'pharmacy',
      'health', 'สุขภาพ', 'หมอ', 'doctor', 'ฟัน', 'dental',
    ],
    'บันเทิง / Entertainment': [
      'netflix', 'youtube', 'spotify', 'game', 'เกม', 'movie', 'หนัง',
      'major', 'sf cinema', 'เมเจอร์', 'concert', 'คอนเสิร์ต',
      'entertainment', 'steam', 'playstation', 'nintendo',
    ],
    'โทรศัพท์ / Phone': [
      'iphone', 'samsung', 'mobile', 'มือถือ', 'phone', 'โทรศัพท์',
      'sim', 'ซิม', 'top up', 'เติมเงิน',
    ],
    'เงินเดือน / Salary': [
      'เงินเดือน', 'salary', 'wage', 'payroll', 'ค่าจ้าง',
    ],
    'โบนัส / Bonus': [
      'bonus', 'โบนัส', 'เงินพิเศษ', 'reward', 'รางวัล',
    ],
    'รายได้เสริม / Extra': [
      'freelance', 'ฟรีแลนซ์', 'part-time', 'ค่าคอม', 'commission',
      'เงินปันผล', 'dividend', 'interest', 'ดอกเบี้ย',
    ],
  };

  /// วิเคราะห์ข้อมูลสลิปและเสนอ category
  /// Analyze slip data and suggest a category
  static String? classify(String? receiver, String? note, String? sender) {
    final textToAnalyze = [
      receiver?.toLowerCase() ?? '',
      note?.toLowerCase() ?? '',
      sender?.toLowerCase() ?? '',
    ].join(' ');

    if (textToAnalyze.trim().isEmpty) return null;

    // หา keyword ที่ match
    String? bestMatch;
    int bestScore = 0;

    for (final entry in _keywordMap.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (textToAnalyze.contains(keyword.toLowerCase())) {
          score++;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestMatch = entry.key;
      }
    }

    return bestMatch;
  }

  /// ตรวจสอบว่ารายการนี้เป็นรายรับหรือรายจ่าย
  /// Determine if transaction is income or expense based on keywords
  static String suggestType(String? text) {
    if (text == null) return 'expense';
    final lowerText = text.toLowerCase();

    const incomeKeywords = [
      'เงินเดือน', 'salary', 'bonus', 'โบนัส', 'income', 'รายรับ',
      'เงินปันผล', 'dividend', 'interest', 'ดอกเบี้ย', 'freelance',
      'commission', 'ค่าคอม', 'refund', 'คืนเงิน',
    ];

    for (final keyword in incomeKeywords) {
      if (lowerText.contains(keyword)) {
        return 'income';
      }
    }

    return 'expense';
  }
}
