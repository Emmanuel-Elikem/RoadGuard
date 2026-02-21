/// OCR Service — On-device text recognition using Google ML Kit.
///
/// Provides a clean abstraction over the ML Kit text recognizer,
/// processing images and extracting text blocks with confidence info.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of an OCR scan containing recognized text blocks.
class OcrResult {
  /// All recognized text as a single string.
  final String fullText;

  /// Individual text blocks with their bounding boxes.
  final List<OcrTextBlock> blocks;

  const OcrResult({required this.fullText, required this.blocks});

  /// Whether any text was recognized.
  bool get hasText => fullText.isNotEmpty;
}

/// A block of recognized text with position info.
class OcrTextBlock {
  final String text;
  final List<OcrTextLine> lines;

  const OcrTextBlock({required this.text, required this.lines});
}

/// A single line of recognized text.
class OcrTextLine {
  final String text;
  final List<String> elements;

  const OcrTextLine({required this.text, required this.elements});
}

/// Service for performing on-device text recognition.
///
/// Uses Google ML Kit's text recognizer which runs entirely on-device
/// (no internet needed — aligns with our offline-first architecture).
class OcrService {
  TextRecognizer? _recognizer;

  /// Lazily initialize the recognizer.
  TextRecognizer get _textRecognizer {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  /// Process an image file and extract text.
  Future<OcrResult> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return _processInputImage(inputImage);
  }

  /// Process an image from its file path.
  Future<OcrResult> processImagePath(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    return _processInputImage(inputImage);
  }

  Future<OcrResult> _processInputImage(InputImage inputImage) async {
    try {
      final recognized = await _textRecognizer.processImage(inputImage);

      final blocks = recognized.blocks.map((block) {
        final lines = block.lines.map((line) {
          return OcrTextLine(
            text: line.text,
            elements: line.elements.map((e) => e.text).toList(),
          );
        }).toList();

        return OcrTextBlock(text: block.text, lines: lines);
      }).toList();

      return OcrResult(fullText: recognized.text, blocks: blocks);
    } catch (e) {
      debugPrint('OCR processing failed: $e');
      return const OcrResult(fullText: '', blocks: []);
    }
  }

  /// Release resources when done.
  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}
