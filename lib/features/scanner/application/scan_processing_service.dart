import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/scan_mode.dart';

/// Thrown when a source file can't be decoded as an image (corrupted file,
/// unsupported format) — callers show a friendly "Unsupported image"
/// message instead of a raw exception.
class ScanProcessingException implements Exception {
  final String message;
  const ScanProcessingException(this.message);
  @override
  String toString() => message;
}

/// One corner of a document quadrilateral, as fractions (0.0–1.0) of the
/// source image's width/height — resolution-independent so the crop editor
/// (which works in on-screen coordinates) and the auto-detector (which
/// works on a downscaled copy) can both produce these without knowing the
/// full-resolution source's exact pixel size up front.
class NormalizedPoint {
  final double x;
  final double y;
  const NormalizedPoint(this.x, this.y);
}

/// The four corners of a document as detected (or manually adjusted),
/// expressed as [NormalizedPoint]s. Unlike a simple crop rectangle, this
/// supports a skewed/rotated quadrilateral so [ScanProcessingService.rectify]
/// can perspective-correct a document photographed at an angle — not just
/// axis-aligned crop it.
class NormalizedQuad {
  final NormalizedPoint topLeft;
  final NormalizedPoint topRight;
  final NormalizedPoint bottomLeft;
  final NormalizedPoint bottomRight;

  const NormalizedQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  /// A quad inset slightly from the full image bounds — used both as the
  /// crop editor's starting point and as the safe fallback when automatic
  /// document detection isn't confident, per the "never silently remove
  /// part of the document" rule.
  static const NormalizedQuad fullImageInset = NormalizedQuad(
    topLeft: NormalizedPoint(0.04, 0.04),
    topRight: NormalizedPoint(0.96, 0.04),
    bottomLeft: NormalizedPoint(0.04, 0.96),
    bottomRight: NormalizedPoint(0.96, 0.96),
  );
}

/// The result of attempting automatic document-edge detection.
class DocumentDetectionResult {
  final NormalizedQuad quad;

  /// False when detection couldn't confidently find a document-like
  /// region (e.g. low contrast against the background) — [quad] is then
  /// [NormalizedQuad.fullImageInset], a safe no-op-ish crop rather than a
  /// guess that might cut off part of the document.
  final bool isConfident;

  const DocumentDetectionResult({required this.quad, required this.isConfident});
}

/// Runs every CPU-bound scan operation (per-mode processing, rotate, crop,
/// thumbnailing) on a background isolate via [compute], so a large photo
/// never freezes the UI thread. Each method reads its source file, decodes
/// it once, and writes a new file into the scanner's temp working
/// directory — it never mutates the source file in place.
class ScanProcessingService {
  Future<Directory> _tempDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'scanner_tmp'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _newTempPath(String prefix, {String extension = 'jpg'}) async {
    final dir = await _tempDir();
    return p.join(
      dir.path,
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
  }

  /// Produces the preview/output image for [mode] from [sourcePath],
  /// applying orientation correction for every mode and mode-specific
  /// color processing for Black and White / Enhance. Returns the new
  /// file's path.
  Future<String> processForMode({
    required String sourcePath,
    required ScanMode mode,
  }) async {
    final outputPath = await _newTempPath('mode_${mode.name}');
    return compute(_processForModeIsolate, _ProcessModeArgs(sourcePath, outputPath, mode));
  }

  Future<String> rotate90(String sourcePath) async {
    final outputPath = await _newTempPath('rotate');
    return compute(_rotateIsolate, _PathArgs(sourcePath, outputPath));
  }

  /// Detects the document's four corners in [sourcePath] — a bright-region
  /// heuristic (see [_detectQuadIsolate]), not a full contour/Canny-based
  /// algorithm. Falls back to [NormalizedQuad.fullImageInset] with
  /// `isConfident: false` whenever the source doesn't clearly separate
  /// from its background, so callers never crop off part of a document
  /// they weren't sure about.
  Future<DocumentDetectionResult> detectDocumentCorners(String sourcePath) {
    return compute(_detectQuadIsolate, sourcePath);
  }

  /// Perspective-corrects the document bounded by [quad] in [sourcePath]
  /// into a flat, cropped rectangle — "scans" a photographed document the
  /// way a flatbed scanner would, rather than merely cropping a skewed
  /// photo. Returns the new file's path.
  Future<String> rectify(String sourcePath, NormalizedQuad quad) async {
    final outputPath = await _newTempPath('rectify');
    return compute(_rectifyIsolate, _RectifyArgs(sourcePath, outputPath, quad));
  }

  Future<String> generateThumbnail(String sourcePath) async {
    final outputPath = await _newTempPath('thumb');
    return compute(_thumbnailIsolate, _PathArgs(sourcePath, outputPath));
  }

  /// Combines each page's already-processed image (in page order) into a
  /// single multi-page PDF, one image per page. Returns the new PDF
  /// file's path.
  Future<String> combinePagesToPdf(List<String> processedImagePaths) async {
    final outputPath = await _newTempPath('scan', extension: 'pdf');
    return compute(
      _combineToPdfIsolate,
      _CombinePdfArgs(processedImagePaths, outputPath),
    );
  }

  Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // Best-effort cleanup only — a leftover temp file is not worth
        // surfacing an error to the user for.
      }
    }
  }
}

class _ProcessModeArgs {
  final String sourcePath;
  final String outputPath;
  final ScanMode mode;
  const _ProcessModeArgs(this.sourcePath, this.outputPath, this.mode);
}

class _PathArgs {
  final String sourcePath;
  final String outputPath;
  const _PathArgs(this.sourcePath, this.outputPath);
}

class _RectifyArgs {
  final String sourcePath;
  final String outputPath;
  final NormalizedQuad quad;
  const _RectifyArgs(this.sourcePath, this.outputPath, this.quad);
}

class _CombinePdfArgs {
  final List<String> imagePaths;
  final String outputPath;
  const _CombinePdfArgs(this.imagePaths, this.outputPath);
}

img.Image _decodeOrThrow(String path) {
  final bytes = File(path).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const ScanProcessingException('Unsupported image.');
  }
  // Physically applies EXIF orientation so every later operation (crop,
  // rotate, mode filters) works in the image's visually-correct
  // orientation instead of having to special-case rotated pixel buffers.
  return img.bakeOrientation(decoded);
}

String _writeJpg(img.Image image, String outputPath, {int quality = 92}) {
  final encoded = img.encodeJpg(image, quality: quality);
  File(outputPath).writeAsBytesSync(encoded);
  return outputPath;
}

String _processForModeIsolate(_ProcessModeArgs args) {
  var image = _decodeOrThrow(args.sourcePath);
  switch (args.mode) {
    case ScanMode.defaultMode:
      break;
    case ScanMode.blackAndWhite:
      image = img.grayscale(image);
      image = img.adjustColor(image, contrast: 1.18, brightness: 1.02);
    case ScanMode.enhance:
      image = img.normalize(image, min: 12, max: 248);
      image = img.adjustColor(
        image,
        contrast: 1.12,
        brightness: 1.05,
        saturation: 1.05,
      );
  }
  return _writeJpg(image, args.outputPath);
}

String _rotateIsolate(_PathArgs args) {
  final image = _decodeOrThrow(args.sourcePath);
  final rotated = img.copyRotate(image, angle: 90);
  return _writeJpg(rotated, args.outputPath);
}

img.Point _toPixelPoint(NormalizedPoint p, int width, int height) {
  return img.Point(
    (p.x.clamp(0.0, 1.0) * (width - 1)),
    (p.y.clamp(0.0, 1.0) * (height - 1)),
  );
}

double _pointDistance(img.Point a, img.Point b) {
  final dx = (a.x - b.x).toDouble();
  final dy = (a.y - b.y).toDouble();
  return math.sqrt(dx * dx + dy * dy);
}

String _rectifyIsolate(_RectifyArgs args) {
  final image = _decodeOrThrow(args.sourcePath);
  final quad = args.quad;

  final topLeft = _toPixelPoint(quad.topLeft, image.width, image.height);
  final topRight = _toPixelPoint(quad.topRight, image.width, image.height);
  final bottomLeft = _toPixelPoint(quad.bottomLeft, image.width, image.height);
  final bottomRight = _toPixelPoint(
    quad.bottomRight,
    image.width,
    image.height,
  );

  // The output canvas is sized from the quad's own edge lengths (the
  // longer of the two roughly-parallel edges each way) so a portrait
  // document doesn't come out squashed into the source photo's landscape
  // aspect ratio, or vice versa.
  final width = math
      .max(
        _pointDistance(topLeft, topRight),
        _pointDistance(bottomLeft, bottomRight),
      )
      .round()
      .clamp(200, 4000);
  final height = math
      .max(
        _pointDistance(topLeft, bottomLeft),
        _pointDistance(topRight, bottomRight),
      )
      .round()
      .clamp(200, 4000);

  final canvas = img.Image(width: width, height: height);
  final rectified = img.copyRectify(
    image,
    topLeft: topLeft,
    topRight: topRight,
    bottomLeft: bottomLeft,
    bottomRight: bottomRight,
    interpolation: img.Interpolation.linear,
    toImage: canvas,
  );
  return _writeJpg(rectified, args.outputPath);
}

/// "Paper-likeness" document detector: downscales the photo, then masks
/// pixels that look like paper — bright **and** low-saturation (paper,
/// even off-white or slightly shadowed, reads as close to neutral
/// gray/white; wood desks, dark tables, keyboards, hands, and floors are
/// virtually always more saturated/colored than that even when similarly
/// bright, which is what makes this more reliable than a pure brightness
/// threshold on e.g. a light wooden desk) — then takes the four extreme
/// points of that mask (min/max of x+y and x-y — a standard fast corner
/// approximation) as the document's corners, and finally nudges each
/// corner slightly outward as a safety margin so a close call errs toward
/// keeping a sliver of background rather than clipping the document.
///
/// This is deliberately not a full contour/Canny-based algorithm — that
/// would need a proper computer-vision library, which risks the kind of
/// instability the original spec explicitly warns against. When the
/// paper-like ratio is too small or too large to trust (e.g. white paper
/// on a white surface, or a failed threshold), this reports
/// `isConfident: false` and returns a safe near-full-frame quad instead of
/// guessing — the caller then leaves the image uncropped and lets the
/// user crop manually, per the "never silently remove part of the
/// document" rule.
DocumentDetectionResult _detectQuadIsolate(String sourcePath) {
  final original = _decodeOrThrow(sourcePath);

  const workingWidth = 500;
  final scale = original.width > workingWidth
      ? workingWidth / original.width
      : 1.0;
  final small = scale < 1.0
      ? img.copyResize(original, width: workingWidth)
      : original;
  final blurred = img.gaussianBlur(small, radius: 3);

  double luminanceSum = 0;
  var count = 0;
  for (final p in blurred) {
    luminanceSum +=
        0.3 * p.rNormalized + 0.59 * p.gNormalized + 0.11 * p.bNormalized;
    count++;
  }
  final meanLuminance = count > 0 ? luminanceSum / count : 0.5;
  final luminanceThreshold = (meanLuminance + 0.08).clamp(0.3, 0.8);
  const saturationThreshold = 0.22;

  num minSum = double.infinity, maxSum = double.negativeInfinity;
  num minDiff = double.infinity, maxDiff = double.negativeInfinity;
  img.Point? topLeft, bottomRight, topRight, bottomLeft;
  var paperCount = 0;

  for (final p in blurred) {
    final r = p.rNormalized, g = p.gNormalized, b = p.bNormalized;
    final luminance = 0.3 * r + 0.59 * g + 0.11 * b;
    final maxChannel = math.max(r, math.max(g, b));
    final minChannel = math.min(r, math.min(g, b));
    // A simple, cheap saturation proxy (full HSV conversion isn't needed
    // just to ask "is this pixel close to neutral gray/white").
    final saturation = maxChannel <= 0 ? 0.0 : (maxChannel - minChannel) / maxChannel;

    if (luminance < luminanceThreshold || saturation > saturationThreshold) {
      continue;
    }
    paperCount++;
    final s = p.x + p.y;
    final d = p.x - p.y;
    if (s < minSum) {
      minSum = s;
      topLeft = img.Point(p.x, p.y);
    }
    if (s > maxSum) {
      maxSum = s;
      bottomRight = img.Point(p.x, p.y);
    }
    if (d > maxDiff) {
      maxDiff = d;
      topRight = img.Point(p.x, p.y);
    }
    if (d < minDiff) {
      minDiff = d;
      bottomLeft = img.Point(p.x, p.y);
    }
  }

  final totalPixels = blurred.width * blurred.height;
  final paperRatio = totalPixels > 0 ? paperCount / totalPixels : 0.0;
  final confident =
      topLeft != null &&
      topRight != null &&
      bottomLeft != null &&
      bottomRight != null &&
      paperRatio > 0.12 &&
      paperRatio < 0.95;

  if (!confident) {
    return const DocumentDetectionResult(
      quad: NormalizedQuad.fullImageInset,
      isConfident: false,
    );
  }

  // Nudge each corner outward from the quad's centroid by a small margin,
  // so a detection that's just barely inside the document's true edge
  // still keeps the whole document rather than shaving off a sliver —
  // consistent with "never silently remove part of the document".
  final centroidX = (topLeft.x + topRight.x + bottomLeft.x + bottomRight.x) / 4;
  final centroidY = (topLeft.y + topRight.y + bottomLeft.y + bottomRight.y) / 4;
  const marginFactor = 0.035;
  img.Point expand(img.Point p) {
    return img.Point(
      (p.x + (p.x - centroidX) * marginFactor).clamp(0, small.width - 1),
      (p.y + (p.y - centroidY) * marginFactor).clamp(0, small.height - 1),
    );
  }

  final invScale = scale < 1.0 ? (1.0 / scale) : 1.0;
  NormalizedPoint normalize(img.Point p) => NormalizedPoint(
    (p.x * invScale) / original.width,
    (p.y * invScale) / original.height,
  );

  return DocumentDetectionResult(
    quad: NormalizedQuad(
      topLeft: normalize(expand(topLeft)),
      topRight: normalize(expand(topRight)),
      bottomLeft: normalize(expand(bottomLeft)),
      bottomRight: normalize(expand(bottomRight)),
    ),
    isConfident: true,
  );
}

String _thumbnailIsolate(_PathArgs args) {
  final image = _decodeOrThrow(args.sourcePath);
  final thumbnail = img.copyResize(image, width: 320);
  return _writeJpg(thumbnail, args.outputPath, quality: 80);
}

Future<String> _combineToPdfIsolate(_CombinePdfArgs args) async {
  final document = pw.Document();
  for (final path in args.imagePaths) {
    final bytes = File(path).readAsBytesSync();
    final image = pw.MemoryImage(bytes);
    document.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }
  final bytes = await document.save();
  File(args.outputPath).writeAsBytesSync(bytes);
  return args.outputPath;
}
