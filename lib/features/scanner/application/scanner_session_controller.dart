import 'package:flutter/foundation.dart';

import '../../../core/models/scan_mode.dart';
import '../../../core/models/scanned_page_draft.dart';

/// Owns the pages captured during one document-scanning session, from the
/// first capture through to the details screen. A new instance is created
/// each time the scanner is opened (see the `/scanner` route) and discarded
/// once the session ends (saved or cancelled) — it is not a long-lived
/// app-wide provider like [DocumentsProvider].
///
/// Phase 1 only ever drives this with placeholder pages (no real camera or
/// file-processing calls), but the add/delete/reorder/select-mode surface
/// here is the same one Phase 2's real capture flow will call into, so the
/// UI built against it now won't need to change shape later.
class ScannerSessionController extends ChangeNotifier {
  final List<ScannedPageDraft> _pages = [];
  String? _selectedPageId;

  List<ScannedPageDraft> get pages => List.unmodifiable(_pages);
  int get pageCount => _pages.length;

  String? get selectedPageId => _selectedPageId;

  ScannedPageDraft? get selectedPage {
    for (final page in _pages) {
      if (page.id == _selectedPageId) return page;
    }
    return _pages.isEmpty ? null : _pages.first;
  }

  /// Adds a new placeholder page (Phase 1, no real image yet) and selects
  /// it.
  ScannedPageDraft addPlaceholderPage() {
    final page = ScannedPageDraft(
      id: 'page-${DateTime.now().microsecondsSinceEpoch}',
    );
    _pages.add(page);
    _selectedPageId = page.id;
    notifyListeners();
    return page;
  }

  /// Adds a page backed by a real captured (camera) or picked (gallery)
  /// image at [imagePath], and selects it.
  ScannedPageDraft addCapturedPage(String imagePath) {
    final page = ScannedPageDraft(
      id: 'page-${DateTime.now().microsecondsSinceEpoch}',
      imagePath: imagePath,
    );
    _pages.add(page);
    _selectedPageId = page.id;
    notifyListeners();
    return page;
  }

  /// Replaces [pageId]'s working image (after crop/rotate) and invalidates
  /// [ScannerSessionController]-level callers' any cached processed
  /// previews for that page, since they were generated from the old image.
  void setPageImage(String pageId, String imagePath) {
    final index = _pages.indexWhere((p) => p.id == pageId);
    if (index == -1) return;
    _pages[index] = _pages[index].copyWith(imagePath: imagePath);
    notifyListeners();
  }

  void selectPage(String pageId) {
    if (_selectedPageId == pageId) return;
    _selectedPageId = pageId;
    notifyListeners();
  }

  void deletePage(String pageId) {
    if (_pages.length <= 1) return;
    final index = _pages.indexWhere((p) => p.id == pageId);
    if (index == -1) return;
    _pages.removeAt(index);
    if (_selectedPageId == pageId) {
      final fallback = index < _pages.length ? index : _pages.length - 1;
      _selectedPageId = _pages[fallback].id;
    }
    notifyListeners();
  }

  void setModeForPage(String pageId, ScanMode mode) {
    final index = _pages.indexWhere((p) => p.id == pageId);
    if (index == -1) return;
    _pages[index] = _pages[index].copyWith(selectedMode: mode);
    notifyListeners();
  }

  /// Discards [pageId] unconditionally — unlike [deletePage] (which keeps
  /// at least one page for the page-strip's "Delete Page" action), this is
  /// used by "Retake", which removes the current page entirely so the next
  /// capture becomes a clean replacement instead of an extra page.
  void discardPage(String pageId) {
    final index = _pages.indexWhere((p) => p.id == pageId);
    if (index == -1) return;
    _pages.removeAt(index);
    if (_selectedPageId == pageId) {
      _selectedPageId = _pages.isEmpty ? null : _pages.last.id;
    }
    notifyListeners();
  }
}
