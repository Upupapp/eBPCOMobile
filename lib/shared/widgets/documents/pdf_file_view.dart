import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../../core/constants/app_constants.dart';
import '../states/error_state.dart';

/// Renders one PDF from a path on disk.
///
/// Extracted from the My Documents preview so the official blank forms could
/// be shown without a second renderer. Owning the failure state is the reason
/// it is a widget rather than a helper: `PDFView` reports a corrupt or
/// unreadable file through callbacks after it has already been laid out, so
/// something has to hold the "it did not render" bit, and every caller
/// otherwise reimplements it — and one of them eventually forgets.
class PdfFileView extends StatefulWidget {
  final String filePath;

  /// Shown in place of the document when it cannot be rendered. Callers say
  /// this differently: a saved document has been deleted or moved, whereas a
  /// bundled form is a packaging fault the applicant did not cause.
  final Widget onFailure;

  const PdfFileView({
    super.key,
    required this.filePath,
    required this.onFailure,
  });

  @override
  State<PdfFileView> createState() => _PdfFileViewState();
}

class _PdfFileViewState extends State<PdfFileView> {
  bool _failed = false;

  void _fail() {
    if (_failed || !mounted) return;
    setState(() => _failed = true);
  }

  @override
  void didUpdateWidget(PdfFileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new file deserves its own attempt; keeping the old failure would show
    // an error for a document that was never tried.
    if (oldWidget.filePath != widget.filePath) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.onFailure;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: PDFView(
        filePath: widget.filePath,
        fitPolicy: FitPolicy.WIDTH,
        onError: (_) => _fail(),
        onPageError: (_, _) => _fail(),
      ),
    );
  }
}

/// The failure state the My Documents preview shows: the applicant's own file
/// has gone.
const Widget missingLocalFileState = ErrorState(
  icon: Icons.error_outline,
  title: 'File Not Available',
  message: 'This PDF has been deleted, moved, or is no longer readable.',
);
