import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  /// ตรวจสอบว่า platform รองรับ OCR หรือไม่
  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Initialize text recognizer
  void _initRecognizer() {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// อ่านข้อความจากรูปภาพ
  /// Extract text from image file
  Future<String?> extractText(String imagePath) async {
    if (!isSupported) {
      debugPrint('OCR is not supported on this platform');
      return null;
    }

    try {
      _initRecognizer();
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('OCR Error: $e');
      return null;
    }
  }

  /// ปิด recognizer เพื่อคืน memory
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
