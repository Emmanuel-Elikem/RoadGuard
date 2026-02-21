/// Image Preprocessor — Crops and enhances camera images for OCR.
///
/// Handles the critical step of extracting just the plate region
/// from a full camera frame and boosting contrast so ML Kit can
/// read the text accurately.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Defines the guide box region as fractions of the full image.
///
/// These constants match the guide overlay dimensions used in the
/// plate scanner screen:
/// - width = 82% of screen width
/// - height = 28% of width (plate aspect ratio)
/// - centered horizontally, shifted 40px up from center
class GuideBoxRegion {
  /// Fraction of the screen width the guide box occupies.
  static const double widthFraction = 0.82;

  /// Height as a fraction of the guide box width (plate aspect ratio).
  static const double aspectRatio = 0.28;

  /// Upward offset from center in logical pixels.
  static const double verticalOffset = 40.0;

  /// Horizontal padding around the crop region (fraction of crop width).
  ///
  /// 15% on each side accounts for plates slightly off-center in the
  /// guide box. Wider padding reduces the risk of clipping plate edges.
  static const double horizontalPadding = 0.15;

  /// Vertical padding around the crop region (fraction of crop height).
  ///
  /// 30% on each side accommodates variance in plate height and vertical
  /// alignment. Taller padding is needed because plates are narrow and
  /// small vertical misalignment matters more proportionally.
  static const double verticalPadding = 0.30;
}

/// Result of image preprocessing.
class PreprocessedImage {
  /// The processed image file (cropped + enhanced).
  final File file;

  /// Whether preprocessing was applied (false = original file used).
  final bool wasProcessed;

  const PreprocessedImage({required this.file, required this.wasProcessed});
}

/// Preprocesses camera images for better OCR accuracy.
///
/// Key operations:
/// 1. Crop to the guide box region (removes background noise)
/// 2. Convert to grayscale (simplifies for OCR)
/// 3. Boost contrast (makes text stand out)
/// 4. Apply sharpening (crisper edges)
class ImagePreprocessor {
  /// Crop and enhance an image for OCR.
  ///
  /// [imageFile] — The raw camera capture.
  /// [screenWidth] / [screenHeight] — The screen dimensions when the
  /// photo was taken (needed to map guide box to image coordinates).
  ///
  /// Returns a new temporary file with the processed image.
  static Future<PreprocessedImage> processForOcr({
    required File imageFile,
    required double screenWidth,
    required double screenHeight,
  }) async {
    try {
      final result = await compute(
        _processInIsolate,
        (imageFile.path, screenWidth, screenHeight),
      );

      if (result == null) {
        return PreprocessedImage(file: imageFile, wasProcessed: false);
      }

      // Write processed image to a temp file
      final tempDir = imageFile.parent;
      final processedFile = File(
        '${tempDir.path}/ocr_processed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await processedFile.writeAsBytes(result);

      return PreprocessedImage(file: processedFile, wasProcessed: true);

    } catch (e) {
      debugPrint('Image preprocessing failed: $e');
      return PreprocessedImage(file: imageFile, wasProcessed: false);
    }
  }

  /// Runs in an isolate to avoid blocking the UI.
  ///
  /// Takes a record `(imagePath, screenWidth, screenHeight)` to
  /// guarantee all arguments are trivially sendable across isolates.
  static Uint8List? _processInIsolate(
    (String imagePath, double screenWidth, double screenHeight) args,
  ) {
    final (imagePath, screenWidth, screenHeight) = args;
    try {
      // Decode the image
      final bytes = File(imagePath).readAsBytesSync();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      // Calculate crop region
      // The camera preview is fitted to cover the screen (FittedBox.cover),
      // so we need to map screen coordinates to image coordinates.
      final cropRect = calculateCropRect(
        imageWidth: original.width,
        imageHeight: original.height,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      );

      // 1. Crop to the guide box area (with some padding)
      final cropped = img.copyCrop(
        original,
        x: cropRect.x,
        y: cropRect.y,
        width: cropRect.width,
        height: cropRect.height,
      );

      // 2. Convert to grayscale
      final grayscale = img.grayscale(cropped);

      // 3. Boost contrast — makes dark text darker, light background lighter
      final contrasted = img.adjustColor(
        grayscale,
        contrast: 1.5,
      );

      // 4. Sharpen for crisper edges
      final sharpened = img.convolution(
        contrasted,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        div: 1,
      );

      // Encode back to JPEG (high quality)
      return Uint8List.fromList(img.encodeJpg(sharpened, quality: 95));

    } catch (e) {
      return null;
    }
  }

  /// Maps the on-screen guide box rectangle to image pixel coordinates.
  ///
  /// The camera preview uses FittedBox.cover, which scales the preview
  /// to fill the screen and may crop edges. We need to account for this
  /// when mapping screen coordinates to image coordinates.
  @visibleForTesting
  static CropRect calculateCropRect({
    required int imageWidth,
    required int imageHeight,
    required double screenWidth,
    required double screenHeight,
  }) {
    // Camera image may be rotated (landscape sensor → portrait display).
    // The CameraPreview widget swaps width/height, so we work with the
    // image as-is (camera plugin handles rotation for JPEG output).
    final imgW = imageWidth.toDouble();
    final imgH = imageHeight.toDouble();

    // FittedBox.cover scaling: scale to fill, then crop overflow
    final screenAspect = screenWidth / screenHeight;
    final imageAspect = imgW / imgH;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspect > screenAspect) {
      // Image is wider than screen — height fills, width is cropped
      scale = imgH / screenHeight;
      offsetX = (imgW - screenWidth * scale) / 2;
    } else {
      // Image is taller than screen — width fills, height is cropped
      scale = imgW / screenWidth;
      offsetY = (imgH - screenHeight * scale) / 2;
    }

    // Guide box in screen coordinates
    final guideW = screenWidth * GuideBoxRegion.widthFraction;
    final guideH = guideW * GuideBoxRegion.aspectRatio;
    final guideLeft = (screenWidth - guideW) / 2;
    final guideTop = (screenHeight - guideH) / 2 - GuideBoxRegion.verticalOffset;

    // Map to image coordinates
    final imgLeft = (guideLeft * scale + offsetX).round();
    final imgTop = (guideTop * scale + offsetY).round();
    final imgCropW = (guideW * scale).round();
    final imgCropH = (guideH * scale).round();

    // Add padding to capture plates not perfectly centered
    final padX = (imgCropW * GuideBoxRegion.horizontalPadding).round();
    final padY = (imgCropH * GuideBoxRegion.verticalPadding).round();

    // Clamp to image bounds
    final x = math.max(0, imgLeft - padX);
    final y = math.max(0, imgTop - padY);
    final w = math.min(imgW.round() - x, imgCropW + padX * 2);
    final h = math.min(imgH.round() - y, imgCropH + padY * 2);

    return CropRect(x: x, y: y, width: w, height: h);
  }
}

/// Rectangle for crop coordinates.
class CropRect {
  final int x;
  final int y;
  final int width;
  final int height;

  const CropRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}
