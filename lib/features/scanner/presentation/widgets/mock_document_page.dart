import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/scan_mode.dart';

/// Phase 1's stand-in for a real captured/processed document image. Draws a
/// simple "page of text" so the three scan modes ([ScanMode]) have
/// something visibly different to apply their color filter to — Phase 2
/// replaces this with the actual captured photo run through real
/// grayscale/enhance processing.
class MockDocumentPage extends StatelessWidget {
  final ScanMode mode;

  const MockDocumentPage({super.key, this.mode = ScanMode.defaultMode});

  ColorFilter? get _filterForMode {
    switch (mode) {
      case ScanMode.defaultMode:
        return null;
      case ScanMode.blackAndWhite:
        // Standard luminance-weighted grayscale matrix, with a mild
        // contrast boost so it reads as a "scanned document" rather than a
        // flat desaturated photo.
        const lr = 0.2126, lg = 0.7152, lb = 0.0722;
        const contrast = 1.15;
        const translate = -0.08 * 255 * contrast;
        return const ColorFilter.matrix(<double>[
          lr * contrast, lg * contrast, lb * contrast, 0, translate,
          lr * contrast, lg * contrast, lb * contrast, 0, translate,
          lr * contrast, lg * contrast, lb * contrast, 0, translate,
          0, 0, 0, 1, 0,
        ]);
      case ScanMode.enhance:
        // Brightness + contrast lift while keeping full color, simulating
        // shadow reduction and readability enhancement.
        const contrast = 1.2;
        const brightness = 18.0;
        const translate = -0.5 * 255 * contrast + 255 * 0.5 + brightness;
        return const ColorFilter.matrix(<double>[
          contrast, 0, 0, 0, translate,
          0, contrast, 0, 0, translate,
          0, 0, contrast, 0, translate,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  Widget _page() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 14,
            color: const Color(0xFFB0263A),
          ),
          const SizedBox(height: 18),
          for (final width in const [
            1.0, 0.95, 0.9, 1.0, 0.6, 0.0,
            0.85, 1.0, 0.92, 0.7, 0.0,
            1.0, 0.5,
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: width == 0.0
                  ? const SizedBox(height: 10)
                  : FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: width,
                      child: Container(
                        height: 9,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
            ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 64,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2563EB), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: const Text(
                'SEAL',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = _filterForMode;
    final page = AspectRatio(
      aspectRatio: 3 / 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
        ),
        child: _page(),
      ),
    );
    return filter == null ? page : ColorFiltered(colorFilter: filter, child: page);
  }
}
