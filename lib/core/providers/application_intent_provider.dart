import 'package:flutter/foundation.dart';

import '../models/application_lineage.dart';

/// Carries a renewal or amendment from the screen that starts it into the
/// wizard that files it.
///
/// The alternative was threading a parameter through sixteen wizards, each of
/// which owns its own draft class with no shared interface. This holds one
/// pending intent instead, and `submitPermitApplication` — the single point
/// every wizard files through — consumes it.
///
/// **A held intent is a hazard, and is treated as one.** An applicant who
/// starts a renewal, backs out, and files something else must not have the
/// renewal attach itself to the new filing. Three things guard that: the
/// intent names its permit type and is only applied to a filing of that type,
/// it is cleared the moment it is consumed, and starting a plain new
/// application from the catalog clears it outright.
class ApplicationIntentProvider extends ChangeNotifier {
  ApplicationLineage? _pending;

  ApplicationLineage? get pending => _pending;

  void start(ApplicationLineage lineage) {
    _pending = lineage;
    notifyListeners();
  }

  /// Returns the pending intent if it belongs to a filing of [permitTypeLabel],
  /// clearing it either way.
  ///
  /// Clearing on a mismatch as well is deliberate: a pending intent that did
  /// not match this filing has been overtaken, and leaving it to match some
  /// later one is exactly the accident this class exists to prevent.
  ApplicationLineage? consumeFor(String? permitTypeLabel) {
    final pending = _pending;
    if (pending == null) return null;
    _pending = null;
    // No notifyListeners: this runs inside a submit handler, and rebuilding
    // the tree under it is how the wizard's own navigation gets lost.
    return pending.appliesTo(permitTypeLabel) ? pending : null;
  }

  void clear() {
    if (_pending == null) return;
    _pending = null;
    notifyListeners();
  }
}
