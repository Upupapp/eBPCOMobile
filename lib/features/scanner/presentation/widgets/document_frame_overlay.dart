import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Viewfinder-style corner-bracket frame drawn over the camera preview (or,
/// in Phase 1, the camera placeholder) so the user can line up all four
/// corners of a physical document before capturing.
class DocumentFrameOverlay extends StatelessWidget {
  const DocumentFrameOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: CustomPaint(
          painter: _CornerBracketsPainter(color: AppColors.textOnPrimary),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  static const double _bracketLength = 32;
  static const double _strokeWidth = 4;

  const _CornerBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void corner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, paint);
      canvas.drawLine(origin, origin + dy, paint);
    }

    const l = _bracketLength;
    // Top-left.
    corner(const Offset(0, 0), const Offset(l, 0), const Offset(0, l));
    // Top-right.
    corner(
      Offset(size.width, 0),
      const Offset(-l, 0),
      const Offset(0, l),
    );
    // Bottom-left.
    corner(
      Offset(0, size.height),
      const Offset(l, 0),
      const Offset(0, -l),
    );
    // Bottom-right.
    corner(
      Offset(size.width, size.height),
      const Offset(-l, 0),
      const Offset(0, -l),
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color;
}
