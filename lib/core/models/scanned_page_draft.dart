import 'scan_mode.dart';

/// One page of an in-progress scan session, before it's been saved into
/// "My Documents". Kept as its own model (rather than folding page state
/// directly into the scanner screens) so a scan session can hold more than
/// one page without the screens or controller needing to change shape —
/// Phase 1 only ever creates a single page, but the multi-page UI (page
/// strip, add/delete/reorder) is built against this list from the start.
///
/// [imagePath] is null for a Phase 1 placeholder page, since no real
/// camera capture or file exists yet; Phase 2 sets it to the captured (or
/// gallery-picked) file's path.
class ScannedPageDraft {
  final String id;
  final String? imagePath;
  final ScanMode selectedMode;

  const ScannedPageDraft({
    required this.id,
    this.imagePath,
    this.selectedMode = ScanMode.defaultMode,
  });

  ScannedPageDraft copyWith({String? imagePath, ScanMode? selectedMode}) {
    return ScannedPageDraft(
      id: id,
      imagePath: imagePath ?? this.imagePath,
      selectedMode: selectedMode ?? this.selectedMode,
    );
  }
}
