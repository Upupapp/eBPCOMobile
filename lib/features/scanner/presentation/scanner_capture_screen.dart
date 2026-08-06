import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/document_picker_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/dialogs/permission_dialogs.dart';
import '../../../shared/widgets/states/error_state.dart';
import '../application/camera_capture_controller.dart';
import '../application/scanner_session_controller.dart';
import 'scanner_preview_screen.dart';
import 'widgets/document_frame_overlay.dart';

IconData _flashIcon(FlashMode mode) {
  switch (mode) {
    case FlashMode.off:
      return Icons.flash_off;
    case FlashMode.auto:
      return Icons.flash_auto;
    case FlashMode.always:
    case FlashMode.torch:
      return Icons.flash_on;
  }
}

String _flashLabel(FlashMode mode) {
  switch (mode) {
    case FlashMode.off:
      return 'Flash off';
    case FlashMode.auto:
      return 'Flash auto';
    case FlashMode.always:
    case FlashMode.torch:
      return 'Flash on';
  }
}

const List<FlashMode> _cyclableFlashModes = [
  FlashMode.off,
  FlashMode.auto,
  FlashMode.always,
];

/// The scanner's entry screen: a live rear-camera preview behind a
/// document alignment frame, with flash/gallery/capture controls. Requests
/// camera permission (with eBPCO's own privacy priming first) the moment
/// it opens, and handles every resulting permission state plus camera
/// init failure with a friendly, non-blocking UI instead of a crash or a
/// silent black screen.
class ScannerCaptureScreen extends StatefulWidget {
  /// When set, this screen adds the next page to an already-open scan
  /// session (the "Add Page" flow from [ScannerPreviewScreen]) instead of
  /// starting a brand new one — capturing pops straight back to that
  /// preview screen instead of pushing a second one.
  final ScannerSessionController? existingController;

  const ScannerCaptureScreen({super.key, this.existingController});

  @override
  State<ScannerCaptureScreen> createState() => _ScannerCaptureScreenState();
}

class _ScannerCaptureScreenState extends State<ScannerCaptureScreen>
    with WidgetsBindingObserver {
  late final ScannerSessionController _sessionController;
  late final CameraCaptureController _cameraController;
  bool get _isAddingPage => widget.existingController != null;
  final PermissionService _permissionService = PermissionService();
  final DocumentPickerService _pickerService = DocumentPickerService();

  AppPermissionStatus? _permissionStatus;
  bool _autoCaptureEnabled = false;
  bool _isImportingFromGallery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionController = widget.existingController ?? ScannerSessionController();
    _cameraController = CameraCaptureController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setUpCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_permissionStatus != AppPermissionStatus.granted) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController.pause();
    } else if (state == AppLifecycleState.resumed) {
      // Don't resume the camera on app-foreground if this capture screen
      // isn't the visible route (e.g. the app was backgrounded while
      // Preview/Crop/Details sit on top of it) — `_goToPreview` already
      // paused it deliberately in that case, and it should stay paused
      // until the user actually navigates back here.
      final isTopRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (isTopRoute && !_cameraController.isReady) {
        _cameraController.initialize();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _setUpCamera() async {
    final status = await requestPermissionWithPriming(
      context,
      permissionService: _permissionService,
      kind: AppPermissionKind.camera,
      primerTitle: scannerCameraPermissionPrimerTitle,
      primerMessage: scannerCameraPermissionPrimerMessage,
      deniedTitle: scannerCameraPermissionDeniedTitle,
      deniedMessage: scannerCameraPermissionDeniedMessage,
    );
    if (!mounted) return;
    setState(() => _permissionStatus = status);
    if (status == AppPermissionStatus.granted) {
      await _cameraController.initialize();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleFlashTap() async {
    final current = _cameraController.flashMode;
    final index = _cyclableFlashModes.indexOf(current);
    final next = _cyclableFlashModes[(index + 1) % _cyclableFlashModes.length];
    await _cameraController.setFlashMode(next);
  }

  void _handleAutoCaptureToggle(bool value) {
    setState(() => _autoCaptureEnabled = value);
    if (value) {
      _showMessage(
        'Automatic edge detection isn\'t available yet — use the shutter '
        'button to capture.',
      );
    }
  }

  Future<void> _handleGalleryTap() async {
    final status = await requestPermissionWithPriming(
      context,
      permissionService: _permissionService,
      kind: AppPermissionKind.photos,
      primerTitle: photosPermissionPrimerTitle,
      primerMessage: photosPermissionPrimerMessage,
    );
    if (status != AppPermissionStatus.granted) {
      if (status == AppPermissionStatus.denied) {
        _showMessage('Photo access is required.');
      }
      return;
    }
    if (!mounted) return;

    setState(() => _isImportingFromGallery = true);
    final result = await _pickerService.pickFromGallery();
    if (!mounted) return;
    setState(() => _isImportingFromGallery = false);

    switch (result.outcome) {
      case DocumentPickOutcome.cancelled:
        return;
      case DocumentPickOutcome.invalidFile:
        _showMessage('Unsupported file format.');
        return;
      case DocumentPickOutcome.error:
        _showMessage('The selected file could not be opened.');
        return;
      case DocumentPickOutcome.success:
        break;
    }

    _sessionController.addCapturedPage(result.picked!.file.path);
    if (!mounted) return;
    await _goToPreview();
  }

  Future<void> _handleCapture() async {
    final path = await _cameraController.capture();
    if (path == null) {
      if (mounted) _showMessage('Capture failed. Please try again.');
      return;
    }
    _sessionController.addCapturedPage(path);
    if (!mounted) return;
    await _goToPreview();
  }

  /// Adding a page onto an existing session: pop back to the preview
  /// screen already on the stack (it rebuilds reactively off the shared
  /// controller). Starting fresh: push the preview screen for the first
  /// time. Either way, the live camera preview is released first — it has
  /// no reason to keep running while Preview/Crop/Details screens sit on
  /// top of this one — and brought back only once the user returns here
  /// (e.g. via Retake), rather than a second capture screen ever needing
  /// to fight this one for the camera hardware.
  Future<void> _goToPreview() async {
    await _cameraController.pause();
    if (!mounted) return;

    if (_isAddingPage) {
      Navigator.of(context).pop();
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ScannerPreviewScreen(controller: _sessionController),
      ),
    );
    if (mounted) await _cameraController.initialize();
  }

  Widget _buildCameraArea() {
    if (_permissionStatus == null) {
      return const _CenteredHint(
        icon: Icons.hourglass_top,
        message: 'Checking camera permission...',
      );
    }
    if (_permissionStatus != AppPermissionStatus.granted) {
      return ErrorState(
        icon: Icons.no_photography_outlined,
        title: 'Camera Permission Required',
        message: scannerCameraPermissionDeniedMessage,
        retryLabel: 'Try Again',
        onRetry: _setUpCamera,
      );
    }

    return AnimatedBuilder(
      animation: _cameraController,
      builder: (context, _) {
        switch (_cameraController.status) {
          case CameraInitStatus.uninitialized:
          case CameraInitStatus.initializing:
            return const _CenteredHint(
              icon: Icons.camera_alt_outlined,
              message: 'Starting camera...',
              showSpinner: true,
            );
          case CameraInitStatus.unavailable:
            return const ErrorState(
              icon: Icons.videocam_off_outlined,
              title: 'Camera Unavailable',
              message:
                  'No camera was found on this device. You can still '
                  'import a document from your gallery.',
              onRetry: null,
            );
          case CameraInitStatus.error:
            return ErrorState(
              icon: Icons.error_outline,
              title: 'Camera Unavailable',
              message: _cameraController.errorMessage ??
                  'The camera could not be started.',
              retryLabel: 'Try Again',
              onRetry: () => _cameraController.initialize(),
            );
          case CameraInitStatus.ready:
            return Stack(
              fit: StackFit.expand,
              children: [
                _CoverCameraPreview(controller: _cameraController.controller!),
                const DocumentFrameOverlay(),
                if (_cameraController.isCapturing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
              ],
            );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady = _cameraController.status == CameraInitStatus.ready;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Document'),
        backgroundColor: Colors.black,
        foregroundColor: AppColors.textOnPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCameraArea(),
                  if (cameraReady)
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: AnimatedBuilder(
                        animation: _cameraController,
                        builder: (context, _) => Semantics(
                          label: _flashLabel(_cameraController.flashMode),
                          button: true,
                          child: _RoundIconButton(
                            icon: _flashIcon(_cameraController.flashMode),
                            onTap: _handleFlashTap,
                          ),
                        ),
                      ),
                    ),
                  if (cameraReady)
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                        ),
                        child: Text(
                          'Position the entire document inside the frame. '
                          'Make sure the text is clear and well-lit.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: 'Import from gallery',
                    button: true,
                    child: _isImportingFromGallery
                        ? const SizedBox(
                            width: AppConstants.minTouchTarget,
                            height: AppConstants.minTouchTarget,
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                            ),
                          )
                        : _RoundIconButton(
                            icon: Icons.photo_library_outlined,
                            onTap: _handleGalleryTap,
                          ),
                  ),
                  AnimatedBuilder(
                    animation: _cameraController,
                    builder: (context, _) {
                      final canCapture =
                          cameraReady && !_cameraController.isCapturing;
                      return Semantics(
                        label: 'Capture document',
                        button: true,
                        child: GestureDetector(
                          onTap: canCapture ? _handleCapture : null,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: canCapture
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.4),
                              border: Border.all(
                                color: AppColors.textOnPrimary,
                                width: 4,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.textOnPrimary,
                              size: 30,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _autoCaptureEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: _handleAutoCaptureToggle,
                      ),
                      Text(
                        'Auto-capture',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
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

/// Fits a [CameraPreview] to cover the available space (like `BoxFit.cover`)
/// instead of the letterboxed default, since the camera's native aspect
/// ratio rarely matches the phone screen's.
class _CoverCameraPreview extends StatelessWidget {
  final CameraController controller;

  const _CoverCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = controller.value.previewSize;
        if (size == null) return const SizedBox.shrink();
        final previewAspectRatio = size.height / size.width;
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxWidth / previewAspectRatio,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }
}

class _CenteredHint extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool showSpinner;

  const _CenteredHint({
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1F1F1F),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            const CircularProgressIndicator(color: AppColors.textOnPrimary)
          else
            Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.body.copyWith(color: AppColors.textOnPrimary),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: AppConstants.minTouchTarget,
            minHeight: AppConstants.minTouchTarget,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.textOnPrimary),
        ),
      ),
    );
  }
}
