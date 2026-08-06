import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/scan_mode.dart';
import '../../../core/models/scanned_page_draft.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/dialogs/confirmation_dialog.dart';
import '../../../shared/widgets/states/empty_state.dart';
import '../../../shared/widgets/states/error_state.dart';
import '../../../shared/widgets/states/loading_view.dart';
import '../application/scan_processing_service.dart';
import '../application/scanner_session_controller.dart';
import 'crop_editor_screen.dart';
import 'scanner_capture_screen.dart';
import 'scanner_details_screen.dart';
import 'widgets/mock_document_page.dart';
import 'widgets/page_thumbnail_strip.dart';
import 'widgets/scan_mode_selector.dart';

/// Shows the page(s) captured so far with the Default / Black and White /
/// Enhance preview modes, plus retake/crop/rotate/save actions and the
/// multi-page management strip.
///
/// Every newly captured/imported page is run through automatic document
/// detection and perspective correction ([ScanProcessingService.rectify])
/// exactly once, right when it's first shown here — cropping out the
/// surrounding table/desk/background and flattening the document the way
/// a flatbed scanner would — before any of the three preview modes are
/// generated from it. Each mode's preview is itself generated from that
/// corrected image on a background isolate and cached per page+mode so
/// switching tabs back and forth doesn't reprocess needlessly.
class ScannerPreviewScreen extends StatefulWidget {
  final ScannerSessionController controller;

  const ScannerPreviewScreen({super.key, required this.controller});

  @override
  State<ScannerPreviewScreen> createState() => _ScannerPreviewScreenState();
}

class _ScannerPreviewScreenState extends State<ScannerPreviewScreen> {
  ScannerSessionController get _controller => widget.controller;
  final ScanProcessingService _processingService = ScanProcessingService();

  final Map<String, Map<ScanMode, String>> _processedCache = {};
  String? _pendingProcessKey;
  bool _processingFailed = false;
  bool _isBusy = false;

  // Auto document-detection/rectify state: run once per page, right after
  // capture/import, before any mode preview is generated.
  final Set<String> _autoRectifiedPageIds = {};
  final Map<String, NormalizedQuad> _lastQuadForPage = {};
  String? _autoDetectingPageId;

  @override
  void dispose() {
    // Best-effort cleanup of every temp working file this session ever
    // produced (raw captures/imports and processed-mode previews). Safe to
    // always run: a successful save already copied the chosen file into
    // permanent My Documents storage via `DocumentStorageService`, so
    // nothing here is the last remaining copy of anything.
    _cleanUpAllTempFiles();
    super.dispose();
  }

  void _cleanUpAllTempFiles() {
    for (final page in _controller.pages) {
      if (page.imagePath != null) {
        _processingService.deleteIfExists(page.imagePath);
      }
    }
    for (final modeMap in _processedCache.values) {
      for (final path in modeMap.values) {
        _processingService.deleteIfExists(path);
      }
    }
  }

  Future<void> _invalidateProcessedCache(String pageId) async {
    final modeMap = _processedCache.remove(pageId);
    if (modeMap == null) return;
    for (final path in modeMap.values) {
      await _processingService.deleteIfExists(path);
    }
  }

  /// Runs once per page, the moment it's first shown: detects the
  /// document's edges and perspective-corrects it, replacing the page's
  /// working image with the flattened, cropped result. On any failure,
  /// per the "never silently remove part of the document" rule, the raw
  /// capture is left untouched and the user is told to crop manually.
  Future<void> _autoDetectAndRectify(ScannedPageDraft page) async {
    final source = page.imagePath;
    if (source == null) {
      _autoRectifiedPageIds.add(page.id);
      if (mounted) setState(() => _autoDetectingPageId = null);
      return;
    }
    try {
      final result = await _processingService.detectDocumentCorners(source);
      final rectifiedPath = await _processingService.rectify(
        source,
        result.quad,
      );
      if (!mounted) return;
      await _invalidateProcessedCache(page.id);
      await _processingService.deleteIfExists(source);
      _lastQuadForPage[page.id] = result.quad;
      _autoRectifiedPageIds.add(page.id);
      setState(() => _autoDetectingPageId = null);
      _controller.setPageImage(page.id, rectifiedPath);
      if (!result.isConfident) {
        _showMessage(
          "Couldn't clearly detect the document's edges — tap Crop to "
          'adjust it manually.',
        );
      }
    } catch (_) {
      _autoRectifiedPageIds.add(page.id);
      if (!mounted) return;
      setState(() => _autoDetectingPageId = null);
      _showMessage('Automatic detection failed. Tap Crop to adjust manually.');
    }
  }

  Future<void> _ensureProcessed(ScannedPageDraft page) async {
    final source = page.imagePath;
    if (source == null) return;
    try {
      final outputPath = await _processingService.processForMode(
        sourcePath: source,
        mode: page.selectedMode,
      );
      if (!mounted) return;
      setState(() {
        _processedCache.putIfAbsent(page.id, () => {})[page.selectedMode] =
            outputPath;
        _pendingProcessKey = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processingFailed = true;
        _pendingProcessKey = null;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    return ConfirmationDialog.show(
      context,
      title: 'Discard Scan?',
      message: 'Your captured document has not been saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Continue Editing',
      isDestructive: true,
    );
  }

  Future<void> _handleRetake() async {
    final page = _controller.selectedPage;
    if (page != null) {
      await _invalidateProcessedCache(page.id);
      await _processingService.deleteIfExists(page.imagePath);
      _lastQuadForPage.remove(page.id);
      _autoRectifiedPageIds.remove(page.id);
      _controller.discardPage(page.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _handleAddPage() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            ScannerCaptureScreen(existingController: _controller),
      ),
    );
  }

  Future<void> _handleDeleteSelectedPage() async {
    final page = _controller.selectedPage;
    if (page == null) return;
    await _invalidateProcessedCache(page.id);
    await _processingService.deleteIfExists(page.imagePath);
    _lastQuadForPage.remove(page.id);
    _autoRectifiedPageIds.remove(page.id);
    _controller.deletePage(page.id);
  }

  Future<void> _handleCrop(ScannedPageDraft page) async {
    if (page.imagePath == null) return;
    final initialQuad =
        _lastQuadForPage[page.id] ?? NormalizedQuad.fullImageInset;
    final quad = await Navigator.of(context).push<NormalizedQuad>(
      MaterialPageRoute(
        builder: (_) => CropEditorScreen(
          imagePath: page.imagePath!,
          initialQuad: initialQuad,
        ),
      ),
    );
    if (quad == null || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final oldPath = page.imagePath!;
      final newPath = await _processingService.rectify(oldPath, quad);
      await _invalidateProcessedCache(page.id);
      await _processingService.deleteIfExists(oldPath);
      _lastQuadForPage[page.id] = quad;
      _controller.setPageImage(page.id, newPath);
    } catch (_) {
      if (mounted) _showMessage('Cropping failed. The original image was kept.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleRotate(ScannedPageDraft page) async {
    if (page.imagePath == null) return;
    setState(() => _isBusy = true);
    try {
      final oldPath = page.imagePath!;
      final newPath = await _processingService.rotate90(oldPath);
      await _invalidateProcessedCache(page.id);
      await _processingService.deleteIfExists(oldPath);
      // A remembered crop quad is only valid for the orientation it was
      // detected/adjusted against — after rotating, Crop should start from
      // a fresh full-frame guess rather than reapply now-mismatched corners.
      _lastQuadForPage.remove(page.id);
      _controller.setPageImage(page.id, newPath);
    } catch (_) {
      if (mounted) _showMessage('Rotation failed. The original image was kept.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _handleSave(ScannedPageDraft page) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ScannerDetailsScreen(
          controller: _controller,
          processedImagePathFor: (p) => _processedCache[p.id]?[p.selectedMode],
        ),
      ),
    );
  }

  Widget _buildPreview(ScannedPageDraft page) {
    if (page.imagePath == null) {
      return MockDocumentPage(mode: page.selectedMode);
    }
    if (_autoDetectingPageId == page.id) {
      return const LoadingView(message: 'Detecting document edges...');
    }
    final cached = _processedCache[page.id]?[page.selectedMode];
    if (cached != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Image.file(
          File(cached),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const ErrorState(
            icon: Icons.broken_image_outlined,
            title: 'Preview Unavailable',
            message: 'This preview image could not be loaded.',
          ),
        ),
      );
    }
    if (_processingFailed) {
      return const ErrorState(
        icon: Icons.broken_image_outlined,
        title: 'Processing Failed',
        message:
            'This preview could not be generated. Try a different mode or '
            'retake the photo.',
      );
    }
    return const LoadingView(message: 'Processing preview...');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscardIfNeeded();
        if (discard && context.mounted) Navigator.of(context).pop();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final page = _controller.selectedPage;

          if (page != null &&
              page.imagePath != null &&
              !_autoRectifiedPageIds.contains(page.id) &&
              _autoDetectingPageId != page.id) {
            _autoDetectingPageId = page.id;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _autoDetectAndRectify(page),
            );
          } else if (page != null &&
              page.imagePath != null &&
              _autoRectifiedPageIds.contains(page.id)) {
            final key = '${page.id}:${page.selectedMode.name}';
            final cached = _processedCache[page.id]?[page.selectedMode];
            if (cached == null && _pendingProcessKey != key) {
              _pendingProcessKey = key;
              _processingFailed = false;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _ensureProcessed(page),
              );
            }
          }

          // Crop/Rotate/Save/Continue all need a settled, already
          // auto-detected image to operate on — blocked while that's still
          // running, in addition to while a crop/rotate is in flight.
          // Retake isn't included: discarding the page is always safe, and
          // an in-flight auto-detect for a discarded page is a no-op (see
          // `ScannerSessionController.setPageImage`'s missing-id guard).
          final blocked = _isBusy || _autoDetectingPageId == page?.id;

          return Scaffold(
            appBar: AppBar(title: const Text('Document Preview')),
            body: page == null
                ? const EmptyState(
                    icon: Icons.image_not_supported_outlined,
                    title: 'No Page Captured',
                    message: 'Go back and capture a document page first.',
                  )
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.screenPaddingHorizontal,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: Center(child: _buildPreview(page))),
                          const SizedBox(height: AppSpacing.sm),
                          ScanModeSelector(
                            selected: page.selectedMode,
                            onChanged: (mode) =>
                                _controller.setModeForPage(page.id, mode),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          PageThumbnailStrip(
                            pages: _controller.pages,
                            selectedPageId: _controller.selectedPageId,
                            onSelectPage: _controller.selectPage,
                            onAddPage: _handleAddPage,
                            onDeleteSelectedPage: _handleDeleteSelectedPage,
                            onReorderTap: () => _showMessage(
                              'Reordering pages will be available soon.',
                            ),
                            onContinue: () => _handleSave(page),
                            enabled: !blocked,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _CompactActionButton(
                                  label: 'Retake',
                                  icon: Icons.refresh,
                                  onPressed: _isBusy ? null : _handleRetake,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: _CompactActionButton(
                                  label: 'Crop',
                                  icon: Icons.crop,
                                  onPressed: blocked
                                      ? null
                                      : () => _handleCrop(page),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: _CompactActionButton(
                                  label: 'Rotate',
                                  icon: Icons.rotate_right,
                                  onPressed: blocked
                                      ? null
                                      : () => _handleRotate(page),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          PrimaryButton(
                            label: 'Save Document',
                            isLoading: _isBusy,
                            onPressed: blocked ? null : () => _handleSave(page),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// A compact icon-over-label action button used for Retake/Crop/Rotate.
/// Stacking the icon above the label (instead of side by side) keeps each
/// label's full text visible even with three of these split across a
/// narrow phone screen, where a horizontal icon+text layout could get
/// tight enough to clip.
class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = enabled ? AppColors.textPrimary : AppColors.textMuted;
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppConstants.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
