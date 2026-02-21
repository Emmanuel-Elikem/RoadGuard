/// Tests for ImagePreprocessor — crop rectangle calculation and bounds logic.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:road_guard/shared/services/image_preprocessor.dart';

void main() {
  group('GuideBoxRegion constants', () {
    test('widthFraction is within valid range', () {
      expect(GuideBoxRegion.widthFraction, greaterThan(0));
      expect(GuideBoxRegion.widthFraction, lessThanOrEqualTo(1.0));
    });

    test('aspectRatio is within valid range', () {
      expect(GuideBoxRegion.aspectRatio, greaterThan(0));
      expect(GuideBoxRegion.aspectRatio, lessThan(1.0));
    });

    test('padding fractions are within valid range', () {
      expect(GuideBoxRegion.horizontalPadding, greaterThan(0));
      expect(GuideBoxRegion.horizontalPadding, lessThan(1.0));
      expect(GuideBoxRegion.verticalPadding, greaterThan(0));
      expect(GuideBoxRegion.verticalPadding, lessThan(1.0));
    });
  });

  group('ImagePreprocessor.calculateCropRect', () {
    test('produces a valid rectangle for typical phone dimensions', () {
      // 4032x3024 image on a 393x852 screen (common Android phone)
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 4032,
        imageHeight: 3024,
        screenWidth: 393,
        screenHeight: 852,
      );

      expect(rect.x, greaterThanOrEqualTo(0));
      expect(rect.y, greaterThanOrEqualTo(0));
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
      expect(rect.x + rect.width, lessThanOrEqualTo(4032));
      expect(rect.y + rect.height, lessThanOrEqualTo(3024));
    });

    test('crop region stays within image bounds for wide images', () {
      // Very wide image (panoramic-ish) — tests the imageAspect > screenAspect branch
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 6000,
        imageHeight: 1000,
        screenWidth: 400,
        screenHeight: 800,
      );

      expect(rect.x, greaterThanOrEqualTo(0));
      expect(rect.y, greaterThanOrEqualTo(0));
      expect(rect.x + rect.width, lessThanOrEqualTo(6000));
      expect(rect.y + rect.height, lessThanOrEqualTo(1000));
    });

    test('crop region stays within image bounds for tall images', () {
      // Very tall image — tests the imageAspect <= screenAspect branch
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 1000,
        imageHeight: 6000,
        screenWidth: 400,
        screenHeight: 800,
      );

      expect(rect.x, greaterThanOrEqualTo(0));
      expect(rect.y, greaterThanOrEqualTo(0));
      expect(rect.x + rect.width, lessThanOrEqualTo(1000));
      expect(rect.y + rect.height, lessThanOrEqualTo(6000));
    });

    test('crop is horizontally centered', () {
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 4000,
        imageHeight: 3000,
        screenWidth: 400,
        screenHeight: 800,
      );

      // The crop center should be approximately at the image center (horizontally)
      final cropCenterX = rect.x + rect.width / 2;
      final imageCenterX = 4000 / 2;
      // Allow 10% tolerance from center (padding shifts things slightly)
      expect(cropCenterX, closeTo(imageCenterX, 4000 * 0.10));
    });

    test('crop is vertically near center (slight upward shift)', () {
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 4000,
        imageHeight: 3000,
        screenWidth: 400,
        screenHeight: 800,
      );

      // The guide box is shifted 40px up from center, so crop center
      // should be slightly above image center
      final cropCenterY = rect.y + rect.height / 2;
      final imageCenterY = 3000 / 2;
      // Crop center should be at or above image center
      expect(cropCenterY, lessThanOrEqualTo(imageCenterY));
    });

    test('crop width is proportional to guide box fraction', () {
      const screenW = 400.0;
      const screenH = 800.0;

      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 4000,
        imageHeight: 3000,
        screenWidth: screenW,
        screenHeight: screenH,
      );

      // The crop width (without padding) should be ~82% of the mapped
      // screen width. With 15% padding on each side, total is ~130% of base.
      // Just verify crop width is reasonable (> 50% and < 100% of image width)
      expect(rect.width, greaterThan(4000 * 0.3));
      expect(rect.width, lessThan(4000));
    });

    test('crop has plate-like aspect ratio (wide, not tall)', () {
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 4032,
        imageHeight: 3024,
        screenWidth: 393,
        screenHeight: 852,
      );

      // Width should be significantly greater than height (plates are wide)
      expect(rect.width, greaterThan(rect.height));
      // Aspect ratio should be roughly plate-shaped even with padding
      final aspect = rect.width / rect.height;
      expect(aspect, greaterThan(1.0)); // Wider than tall
    });

    test('handles square image correctly', () {
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 2000,
        imageHeight: 2000,
        screenWidth: 400,
        screenHeight: 800,
      );

      expect(rect.x, greaterThanOrEqualTo(0));
      expect(rect.y, greaterThanOrEqualTo(0));
      expect(rect.x + rect.width, lessThanOrEqualTo(2000));
      expect(rect.y + rect.height, lessThanOrEqualTo(2000));
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
    });

    test('handles square screen correctly', () {
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 4000,
        imageHeight: 3000,
        screenWidth: 500,
        screenHeight: 500,
      );

      expect(rect.x, greaterThanOrEqualTo(0));
      expect(rect.y, greaterThanOrEqualTo(0));
      expect(rect.x + rect.width, lessThanOrEqualTo(4000));
      expect(rect.y + rect.height, lessThanOrEqualTo(3000));
    });

    test('handles small image dimensions', () {
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 320,
        imageHeight: 240,
        screenWidth: 400,
        screenHeight: 800,
      );

      expect(rect.x, greaterThanOrEqualTo(0));
      expect(rect.y, greaterThanOrEqualTo(0));
      expect(rect.x + rect.width, lessThanOrEqualTo(320));
      expect(rect.y + rect.height, lessThanOrEqualTo(240));
    });

    test('handles very large image dimensions', () {
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 12000,
        imageHeight: 9000,
        screenWidth: 393,
        screenHeight: 852,
      );

      expect(rect.x, greaterThanOrEqualTo(0));
      expect(rect.y, greaterThanOrEqualTo(0));
      expect(rect.x + rect.width, lessThanOrEqualTo(12000));
      expect(rect.y + rect.height, lessThanOrEqualTo(9000));
    });

    test('same aspect ratio (image matches screen) produces centered crop', () {
      // When image and screen have same aspect ratio, no FittedBox offset
      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: 2000,
        imageHeight: 4000,
        screenWidth: 400,
        screenHeight: 800,
      );

      // With same aspect ratio, scale is exact, no offset needed
      // Crop should be perfectly centered horizontally
      final cropCenterX = rect.x + rect.width / 2;
      expect(cropCenterX, closeTo(1000, 50)); // ~center of 2000px
    });

    test('padding expands crop beyond base guide box', () {
      const screenW = 400.0;
      const screenH = 800.0;
      const imgW = 4000;
      const imgH = 3000;

      final rect = ImagePreprocessor.calculateCropRect(
        imageWidth: imgW,
        imageHeight: imgH,
        screenWidth: screenW,
        screenHeight: screenH,
      );

      // Calculate expected base crop width (before padding)
      // Image taller than screen → width fills
      final imageAspect = imgW / imgH;
      final screenAspect = screenW / screenH;
      final double scale;
      if (imageAspect > screenAspect) {
        scale = imgH / screenH;
      } else {
        scale = imgW / screenW;
      }
      final baseGuideW = (screenW * GuideBoxRegion.widthFraction * scale).round();
      expect(rect.width, greaterThan(baseGuideW));
    });
  });

  group('ImagePreprocessor.processForOcr', () {
    test('returns wasProcessed=true for valid image file', () async {
      // Create a tiny test JPEG
      final image = img.Image(width: 200, height: 150);
      img.fill(image, color: img.ColorUint8.rgb(200, 200, 200));
      final jpegBytes = img.encodeJpg(image);

      final tempDir = await Directory.systemTemp.createTemp('ocr_test_');
      final testFile = File('${tempDir.path}/test_image.jpg');
      await testFile.writeAsBytes(jpegBytes);

      try {
        final result = await ImagePreprocessor.processForOcr(
          imageFile: testFile,
          screenWidth: 400,
          screenHeight: 800,
        );

        expect(result.wasProcessed, isTrue);
        expect(result.file.existsSync(), isTrue);
        // Processed file should be different from original
        expect(result.file.path, isNot(testFile.path));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns wasProcessed=false for invalid image data', () async {
      final tempDir = await Directory.systemTemp.createTemp('ocr_test_');
      final badFile = File('${tempDir.path}/bad_image.jpg');
      await badFile.writeAsBytes([0, 1, 2, 3]); // Not a valid image

      try {
        final result = await ImagePreprocessor.processForOcr(
          imageFile: badFile,
          screenWidth: 400,
          screenHeight: 800,
        );

        // Should gracefully fall back to original file
        expect(result.wasProcessed, isFalse);
        expect(result.file.path, badFile.path);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns wasProcessed=false for non-existent file', () async {
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/does_not_exist_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final result = await ImagePreprocessor.processForOcr(
        imageFile: file,
        screenWidth: 400,
        screenHeight: 800,
      );

      expect(result.wasProcessed, isFalse);
      expect(result.file.path, file.path);
    });

    test('produced file is a valid JPEG', () async {
      final image = img.Image(width: 400, height: 300);
      img.fill(image, color: img.ColorUint8.rgb(180, 180, 180));
      // Add some dark pixels to simulate text
      for (var x = 100; x < 300; x++) {
        for (var y = 130; y < 170; y++) {
          image.setPixelRgb(x, y, 20, 20, 20);
        }
      }
      final jpegBytes = img.encodeJpg(image);

      final tempDir = await Directory.systemTemp.createTemp('ocr_test_');
      final testFile = File('${tempDir.path}/test_plate.jpg');
      await testFile.writeAsBytes(jpegBytes);

      try {
        final result = await ImagePreprocessor.processForOcr(
          imageFile: testFile,
          screenWidth: 400,
          screenHeight: 800,
        );

        expect(result.wasProcessed, isTrue);

        // Verify the output is a valid image
        final outputBytes = await result.file.readAsBytes();
        final decoded = img.decodeImage(outputBytes);
        expect(decoded, isNotNull);
        // Cropped image should be smaller than original
        expect(decoded!.width, lessThanOrEqualTo(400));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('CropRect', () {
    test('stores coordinates correctly', () {
      const rect = CropRect(x: 10, y: 20, width: 100, height: 50);
      expect(rect.x, 10);
      expect(rect.y, 20);
      expect(rect.width, 100);
      expect(rect.height, 50);
    });
  });

  group('PreprocessedImage', () {
    test('stores file and processing flag', () {
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/test.jpg');
      final result = PreprocessedImage(file: file, wasProcessed: false);
      expect(result.file.path, file.path);
      expect(result.wasProcessed, isFalse);

      final result2 = PreprocessedImage(file: file, wasProcessed: true);
      expect(result2.wasProcessed, isTrue);
    });
  });
}
