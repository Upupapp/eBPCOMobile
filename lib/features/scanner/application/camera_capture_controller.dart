import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show DeviceOrientation;

/// Where [CameraCaptureController] currently stands, so the capture screen
/// can render the right placeholder/error UI instead of guessing from
/// `CameraController` internals.
enum CameraInitStatus {
  uninitialized,
  initializing,
  ready,

  /// No camera hardware was found on this device.
  unavailable,

  /// Initialization threw — a friendly [CameraCaptureController.errorMessage]
  /// is set alongside this.
  error,
}

/// Owns exactly one [CameraController] for the scanner's live preview:
/// picks the rear camera, initializes/disposes it, exposes flash mode, and
/// guards against overlapping capture calls or more than one live
/// controller existing at once. A new instance belongs to one
/// [ScannerCaptureScreen] mount — the screen calls [dispose] when it goes
/// away (backgrounded or popped) and creates a fresh controller to resume,
/// rather than this class trying to survive across lifecycle transitions
/// itself.
class CameraCaptureController extends ChangeNotifier {
  CameraController? _controller;
  CameraInitStatus status = CameraInitStatus.uninitialized;
  String? errorMessage;
  bool isCapturing = false;
  FlashMode flashMode = FlashMode.off;

  CameraController? get controller => _controller;
  bool get isReady =>
      status == CameraInitStatus.ready &&
      (_controller?.value.isInitialized ?? false);

  Future<void> initialize() async {
    if (status == CameraInitStatus.initializing) return;
    status = CameraInitStatus.initializing;
    errorMessage = null;
    notifyListeners();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        status = CameraInitStatus.unavailable;
        notifyListeners();
        return;
      }

      final rearCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      try {
        await controller.setFlashMode(flashMode);
      } on CameraException {
        // Flash isn't supported on every device — capture still works
        // without it, so this isn't a fatal initialization error.
      }
      try {
        // Locks the *captured photo's* orientation to portrait regardless
        // of how the phone is physically rotated while framing the shot.
        // Without this, some Android camera implementations tag (or fail
        // to tag) EXIF orientation inconsistently when the device is held
        // in landscape, which fed a sideways/incorrectly-shaped image
        // into document detection and produced a bad crop. The scanner
        // UI itself is portrait-only anyway, so there's no workflow this
        // gives up.
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } on CameraException {
        // Not all platforms/devices support locking — detection still
        // runs (see ScanProcessingService's own EXIF-bake step), just
        // without this extra layer of protection.
      }

      _controller = controller;
      status = CameraInitStatus.ready;
    } on CameraException catch (e) {
      errorMessage = e.description ?? 'The camera could not be started.';
      status = CameraInitStatus.error;
    } catch (_) {
      errorMessage = 'The camera could not be started.';
      status = CameraInitStatus.error;
    }
    notifyListeners();
  }

  Future<void> setFlashMode(FlashMode mode) async {
    flashMode = mode;
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      try {
        await controller.setFlashMode(mode);
      } on CameraException {
        // Ignore unsupported flash modes; the requested mode is still
        // remembered for when a mode that supports it becomes active.
      }
    }
    notifyListeners();
  }

  /// Captures a still photo and returns its temporary file path, or null if
  /// the camera isn't ready, a capture is already in flight, or the
  /// underlying capture failed.
  Future<String?> capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    if (isCapturing) return null;

    isCapturing = true;
    notifyListeners();
    try {
      final file = await controller.takePicture();
      return file.path;
    } on CameraException {
      return null;
    } finally {
      isCapturing = false;
      notifyListeners();
    }
  }

  /// Tears down the underlying [CameraController] (releasing the hardware)
  /// without disposing this [ChangeNotifier] itself — used when the app is
  /// backgrounded, so [initialize] can bring the camera back on resume
  /// instead of the whole controller needing to be recreated.
  Future<void> pause() async {
    final controller = _controller;
    _controller = null;
    status = CameraInitStatus.uninitialized;
    notifyListeners();
    if (controller != null) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    // Fire-and-forget: CameraController.dispose() is async, but
    // ChangeNotifier.dispose() is sync, and nothing needs to await this
    // completing before the controller object itself is torn down.
    controller?.dispose();
    super.dispose();
  }
}
