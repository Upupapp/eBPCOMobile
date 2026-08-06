import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';
import '../../../shared/widgets/states/loading_view.dart';
import '../application/scan_processing_service.dart';

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

const double _handleTouchSize = 44;

/// Lets the user fine-tune the document's four corners — independently
/// draggable, not constrained to a rectangle — so a document photographed
/// at an angle can still be perspective-corrected accurately even when
/// automatic detection ([ScanProcessingService.detectDocumentCorners])
/// gets it only approximately right.
class CropEditorScreen extends StatefulWidget {
  final String imagePath;

  /// The quad to start from — normally the auto-detected corners, so the
  /// user is fine-tuning rather than drawing from scratch.
  final NormalizedQuad initialQuad;

  const CropEditorScreen({
    super.key,
    required this.imagePath,
    required this.initialQuad,
  });

  @override
  State<CropEditorScreen> createState() => _CropEditorScreenState();
}

class _CropEditorScreenState extends State<CropEditorScreen> {
  final ScanProcessingService _processingService = ScanProcessingService();

  ui.Image? _image;
  bool _loadFailed = false;
  bool _isDetecting = false;
  Size? _renderedSize;

  late Offset _topLeft;
  late Offset _topRight;
  late Offset _bottomLeft;
  late Offset _bottomRight;

  @override
  void initState() {
    super.initState();
    _applyQuad(widget.initialQuad);
    _load();
  }

  void _applyQuad(NormalizedQuad quad) {
    _topLeft = Offset(quad.topLeft.x, quad.topLeft.y);
    _topRight = Offset(quad.topRight.x, quad.topRight.y);
    _bottomLeft = Offset(quad.bottomLeft.x, quad.bottomLeft.y);
    _bottomRight = Offset(quad.bottomRight.x, quad.bottomRight.y);
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _image = frame.image);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleReset() {
    setState(() => _applyQuad(widget.initialQuad));
  }

  Future<void> _handleAutoDetectAgain() async {
    setState(() => _isDetecting = true);
    try {
      final result = await _processingService.detectDocumentCorners(
        widget.imagePath,
      );
      if (!mounted) return;
      setState(() {
        _applyQuad(result.quad);
        _isDetecting = false;
      });
      if (!result.isConfident) {
        _showMessage(
          "Couldn't confidently detect the document edges — adjust the "
          'corners manually.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDetecting = false);
      _showMessage('Detection failed. Adjust the corners manually.');
    }
  }

  void _handleApply() {
    Navigator.of(context).pop(
      NormalizedQuad(
        topLeft: NormalizedPoint(_topLeft.dx, _topLeft.dy),
        topRight: NormalizedPoint(_topRight.dx, _topRight.dy),
        bottomLeft: NormalizedPoint(_bottomLeft.dx, _bottomLeft.dy),
        bottomRight: NormalizedPoint(_bottomRight.dx, _bottomRight.dy),
      ),
    );
  }

  void _updateCorner(_Corner corner, Offset normalizedDelta) {
    setState(() {
      Offset clamp(Offset o) => Offset(
        (o.dx + normalizedDelta.dx).clamp(0.0, 1.0),
        (o.dy + normalizedDelta.dy).clamp(0.0, 1.0),
      );
      switch (corner) {
        case _Corner.topLeft:
          _topLeft = clamp(_topLeft);
        case _Corner.topRight:
          _topRight = clamp(_topRight);
        case _Corner.bottomLeft:
          _bottomLeft = clamp(_bottomLeft);
        case _Corner.bottomRight:
          _bottomRight = clamp(_bottomRight);
      }
    });
  }

  Widget _handle(_Corner corner, Offset position, Size renderedSize) {
    return Positioned(
      left: position.dx * renderedSize.width - _handleTouchSize / 2,
      top: position.dy * renderedSize.height - _handleTouchSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          final size = _renderedSize;
          if (size == null) return;
          _updateCorner(
            corner,
            Offset(details.delta.dx / size.width, details.delta.dy / size.height),
          );
        },
        child: Container(
          width: _handleTouchSize,
          height: _handleTouchSize,
          alignment: Alignment.center,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.textOnPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: const Text('Crop Document'),
      ),
      body: SafeArea(
        child: _loadFailed
            ? const Center(
                child: Text(
                  'This image could not be opened for cropping.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : _image == null
            ? const LoadingView(message: 'Loading image...')
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final image = _image!;
                          final aspectRatio = image.width / image.height;
                          var width = constraints.maxWidth;
                          var height = width / aspectRatio;
                          if (height > constraints.maxHeight) {
                            height = constraints.maxHeight;
                            width = height * aspectRatio;
                          }
                          _renderedSize = Size(width, height);

                          return SizedBox(
                            width: width,
                            height: height,
                            child: Stack(
                              children: [
                                Positioned.fill(child: RawImage(image: image)),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _QuadOverlayPainter(
                                      topLeft: _topLeft,
                                      topRight: _topRight,
                                      bottomLeft: _bottomLeft,
                                      bottomRight: _bottomRight,
                                    ),
                                  ),
                                ),
                                _handle(_Corner.topLeft, _topLeft, _renderedSize!),
                                _handle(
                                  _Corner.topRight,
                                  _topRight,
                                  _renderedSize!,
                                ),
                                _handle(
                                  _Corner.bottomLeft,
                                  _bottomLeft,
                                  _renderedSize!,
                                ),
                                _handle(
                                  _Corner.bottomRight,
                                  _bottomRight,
                                  _renderedSize!,
                                ),
                                if (_isDetecting)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(
                                      color: AppColors.textOnPrimary,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                label: 'Reset',
                                icon: Icons.replay,
                                onPressed: _isDetecting ? null : _handleReset,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: SecondaryButton(
                                label: 'Auto Detect',
                                icon: Icons.auto_fix_high,
                                onPressed: _isDetecting
                                    ? null
                                    : _handleAutoDetectAgain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        PrimaryButton(
                          label: 'Apply Crop',
                          onPressed: _isDetecting ? null : _handleApply,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _QuadOverlayPainter extends CustomPainter {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  const _QuadOverlayPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset scale(Offset o) => Offset(o.dx * size.width, o.dy * size.height);
    final quadPath = Path()
      ..moveTo(scale(topLeft).dx, scale(topLeft).dy)
      ..lineTo(scale(topRight).dx, scale(topRight).dy)
      ..lineTo(scale(bottomRight).dx, scale(bottomRight).dy)
      ..lineTo(scale(bottomLeft).dx, scale(bottomLeft).dy)
      ..close();

    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final fullPath = Path()..addRect(Offset.zero & size);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, quadPath),
      dimPaint,
    );

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(quadPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _QuadOverlayPainter oldDelegate) =>
      oldDelegate.topLeft != topLeft ||
      oldDelegate.topRight != topRight ||
      oldDelegate.bottomLeft != bottomLeft ||
      oldDelegate.bottomRight != bottomRight;
}
