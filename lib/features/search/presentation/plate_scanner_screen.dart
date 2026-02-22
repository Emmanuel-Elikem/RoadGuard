/// Plate Scanner Screen — Camera viewfinder for scanning car numbers.
///
/// Uses the device camera with a guide overlay to help passengers
/// frame the plate number. OCR processes the image on-device.
library;

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:road_guard/core/theme/app_colors.dart';
import 'package:road_guard/core/theme/app_dimensions.dart';
import 'package:road_guard/shared/services/image_preprocessor.dart';
import 'package:road_guard/shared/services/ocr_service.dart';
import 'package:road_guard/shared/services/permission_service.dart';
import 'package:road_guard/shared/services/plate_recognition_service.dart';
import 'package:road_guard/shared/utils/plate_number_formatter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Screen that opens the camera for scanning a vehicle plate number.
///
/// Returns the scanned plate number as a [String] via [Navigator.pop].
/// Returns `null` if the user cancels or scanning fails.
class PlateScannerScreen extends StatefulWidget {
  /// Services can be injected for testing; defaults to real implementations.
  final OcrService? ocrService;
  final PlateRecognitionService? plateRecognitionService;

  const PlateScannerScreen({
    super.key,
    this.ocrService,
    this.plateRecognitionService,
  });

  @override
  State<PlateScannerScreen> createState() => _PlateScannerScreenState();
}

class _PlateScannerScreenState extends State<PlateScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _detectedPlate;
  bool _flashOn = false;
  final _plateEditController = TextEditingController();

  late final OcrService _ocrService;
  late final PlateRecognitionService _plateRecognition;
  late final bool _ownsOcrService;

  @override
  void initState() {
    super.initState();
    _ownsOcrService = widget.ocrService == null;
    _ocrService = widget.ocrService ?? OcrService();
    _plateRecognition = widget.plateRecognitionService ?? PlateRecognitionService();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _plateEditController.dispose();
    if (_ownsOcrService) _ocrService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      final ctrl = _cameraController;
      _cameraController = null;
      ctrl?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Check camera permission first
      var camState = await PermissionService.instance.checkCameraPermission();
      if (!camState.canUseCamera) {
        camState = await PermissionService.instance.requestCameraPermission();
      }
      if (!camState.canUseCamera) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = camState.message;
          });
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }

      // Use the back camera (index 0 is usually rear)
      final camera = _cameras!.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not start the camera. '
              'Check that camera access is allowed in Settings.';
        });
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing || _cameraController == null) return;

    // Capture screen size before async gap
    final screenSize = MediaQuery.of(context).size;

    setState(() {
      _isProcessing = true;
      _detectedPlate = null;
    });

    File? file;
    PreprocessedImage? processed;
    try {
      final image = await _cameraController!.takePicture();
      file = File(image.path);

      // Crop to the guide box region and enhance for OCR
      processed = await ImagePreprocessor.processForOcr(
        imageFile: file,
        screenWidth: screenSize.width,
        screenHeight: screenSize.height,
      );

      final ocrResult = await _ocrService.processImage(processed.file);

      if (!ocrResult.hasText) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _detectedPlate = null;
          });
          _showSnackBar(
            'No text found. Move closer to the car number and try again.',
          );
        }
        return;
      }

      final candidates = _plateRecognition.extractPlates(ocrResult);

      if (candidates.isEmpty) {
        // No plate-like text at all — show the full OCR text for editing
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _detectedPlate = ocrResult.fullText.trim().toUpperCase();
            _plateEditController.text = _detectedPlate!;
          });
        }
        return;
      }

      // Take the best candidate
      final best = candidates.first;
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _detectedPlate = best.plateNumber;
          _plateEditController.text = best.plateNumber;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnackBar(
          'Could not read the number. Try again or type it manually.',
        );
      }
    } finally {
      if (file != null) _cleanupFiles(file, processed);
    }
  }

  /// Clean up temporary image files.
  void _cleanupFiles(File original, PreprocessedImage? processed) {
    try {
      original.deleteSync();
    } catch (_) {}
    if (processed != null && processed.wasProcessed) {
      try {
        processed.file.deleteSync();
      } catch (_) {}
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      _flashOn = !_flashOn;
      await _cameraController!.setFlashMode(
        _flashOn ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _confirmPlate() {
    final text = _plateEditController.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text.toUpperCase());
    }
  }

  void _retake() {
    setState(() {
      _detectedPlate = null;
      _plateEditController.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            Center(child: _CameraPreviewCover(_cameraController!))
          else if (_hasError)
            _ErrorView(message: _errorMessage ?? 'Camera not available')
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Guide overlay
          if (_isInitialized && _detectedPlate == null)
            const _ScanGuideOverlay(),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + AppDimensions.spacingSm,
            left: AppDimensions.spacingSm,
            right: AppDimensions.spacingSm,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
                // Flash toggle
                if (_isInitialized)
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      _flashOn ? LucideIcons.zapOff : LucideIcons.zap,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _detectedPlate != null
                ? _PlateConfirmation(
                    controller: _plateEditController,
                    onConfirm: _confirmPlate,
                    onRetake: _retake,
                    colorScheme: colorScheme,
                    theme: theme,
                  )
                : _CaptureControls(
                    isProcessing: _isProcessing,
                    onCapture: _captureAndProcess,
                    theme: theme,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Camera Preview ────────────────────────────────────────

/// Wraps the camera preview in FittedBox.cover to fill the screen.
class _CameraPreviewCover extends StatelessWidget {
  final CameraController controller;

  const _CameraPreviewCover(this.controller);

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: controller.buildPreview(),
        ),
      ),
    );
  }
}

// ─── Scan Guide Overlay ────────────────────────────────────

class _ScanGuideOverlay extends StatelessWidget {
  const _ScanGuideOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GuideBoxPainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Position the hint text below the guide box
              const SizedBox(
                  height: AppDimensions.spacingXxxl + AppDimensions.spacingXxl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  'Position the car number inside the frame',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a rounded guide rectangle with semi-transparent overlay.
class _GuideBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent overlay
    final overlayPaint = Paint()..color = Colors.black45;

    // Guide box dimensions — matches GuideBoxRegion used by ImagePreprocessor
    final boxWidth = size.width * GuideBoxRegion.widthFraction;
    final boxHeight = boxWidth * GuideBoxRegion.aspectRatio;
    final left = (size.width - boxWidth) / 2;
    final top = (size.height - boxHeight) / 2 - GuideBoxRegion.verticalOffset;
    final guideRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxWidth, boxHeight),
      const Radius.circular(AppDimensions.radiusMd),
    );

    // Draw overlay with cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(guideRect);
    final combinedPath =
        Path.combine(PathOperation.difference, overlayPath, cutoutPath);
    canvas.drawPath(combinedPath, overlayPaint);

    // Draw guide border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(guideRect, borderPaint);

    // Draw corner accents
    final accentPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLen = AppDimensions.spacingLg;
    final r = guideRect.outerRect;

    // Top-left
    canvas.drawLine(Offset(r.left, r.top + cornerLen),
        Offset(r.left, r.top), accentPaint);
    canvas.drawLine(Offset(r.left, r.top),
        Offset(r.left + cornerLen, r.top), accentPaint);

    // Top-right
    canvas.drawLine(Offset(r.right - cornerLen, r.top),
        Offset(r.right, r.top), accentPaint);
    canvas.drawLine(Offset(r.right, r.top),
        Offset(r.right, r.top + cornerLen), accentPaint);

    // Bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - cornerLen),
        Offset(r.left, r.bottom), accentPaint);
    canvas.drawLine(Offset(r.left, r.bottom),
        Offset(r.left + cornerLen, r.bottom), accentPaint);

    // Bottom-right
    canvas.drawLine(Offset(r.right - cornerLen, r.bottom),
        Offset(r.right, r.bottom), accentPaint);
    canvas.drawLine(Offset(r.right, r.bottom),
        Offset(r.right, r.bottom - cornerLen), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Capture Controls ──────────────────────────────────────

class _CaptureControls extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onCapture;
  final ThemeData theme;

  const _CaptureControls({
    required this.isProcessing,
    required this.onCapture,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        MediaQuery.of(context).padding.bottom + AppDimensions.spacingLg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Capture button
          GestureDetector(
            onTap: isProcessing ? null : onCapture,
            child: Container(
              width: AppDimensions.captureButtonSize,
              height: AppDimensions.captureButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: isProcessing ? Colors.white24 : Colors.white30,
              ),
              child: isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(
                      LucideIcons.camera,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            isProcessing ? 'Reading...' : 'Tap to scan',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Plate Confirmation ────────────────────────────────────

class _PlateConfirmation extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _PlateConfirmation({
    required this.controller,
    required this.onConfirm,
    required this.onRetake,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
        MediaQuery.of(context).padding.bottom + AppDimensions.spacingLg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            'Car number found — tap to edit',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),

          // Editable plate field
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [PlateNumberFormatter()],
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLg,
                vertical: AppDimensions.spacingMd,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              suffixIcon: Icon(
                LucideIcons.pencil,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  label: const Text('Scan again'),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(AppDimensions.buttonHeightLg),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: const Text('Use this number'),
                  style: FilledButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(AppDimensions.buttonHeightLg),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Error View ────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.cameraOff,
              size: 56,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  child: const Text('Go back'),
                ),
                if (message.contains('allow')) ...[
                  const SizedBox(width: AppDimensions.spacingMd),
                  FilledButton(
                    onPressed: () => openAppSettings(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Open Settings'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
