import 'package:flutter/material.dart';

import '../models/notification_event.dart';
import '../notifications/notification_evaluator.dart';
import '../models/notification_preferences_model.dart';
import '../repositories/notifications_repository.dart';

/// The applicant's notification queue.
///
/// Organised around resolution rather than chronology. A P1 stays outstanding
/// until its underlying condition clears, regardless of whether it has been
/// read — an applicant who opens a Letter of Instruction and closes it again
/// has corrected nothing.
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({
    required this._repository,
    DateTime Function()? clock,
    this.preferences = const NotificationPreferences(),
  })  : _clock = clock ?? DateTime.now {
    _load();
  }

  final NotificationsRepository _repository;
  final DateTime Function() _clock;

  /// The moment this provider judges everything against — quiet hours, read
  /// and resolved stamps, and the "Today"/"Yesterday" grouping the feed draws.
  ///
  /// Exposed so the screen labels days against the same clock that stamped the
  /// events. A screen reading its own `DateTime.now()` is a second source of
  /// truth for today, and the two disagree wherever the clock is pinned.
  DateTime get now => _clock();

  bool _isLoading = true;
  Object? _loadError;
  final List<NotificationEvent> _events = [];

  bool get isLoading => _isLoading;

  /// Why the last fetch failed, or null if it did not.
  Object? get loadError => _loadError;
  bool get hasLoadError => _loadError != null;
  NotificationPreferences preferences;

  List<NotificationEvent> get events => List.unmodifiable(_events);

  /// Unresolved P1s, most urgent first. Drives the tab badge.
  List<NotificationEvent> get needsAction =>
      _events.where((e) => e.isOutstandingAction).toList();

  /// P2 progress events, newest first.
  List<NotificationEvent> get updates => _events
      .where(
        (e) =>
            e.priority == NotificationPriority.progress &&
            !e.isOutstandingAction,
      )
      .toList();

  /// P3 ambient events and everything already resolved.
  List<NotificationEvent> get earlier => _events
      .where(
        (e) =>
            e.priority == NotificationPriority.ambient ||
            (e.priority == NotificationPriority.action && e.isResolved),
      )
      .toList();

  /// The tab badge counts *things you must do*, not things you have not
  /// looked at. Marking everything read must not change it.
  int get actionBadgeCount => needsAction.length;

  int get unreadCount => _events.where((e) => !e.isRead).length;

  List<NotificationEvent> get recent => _events.take(3).toList();

  Future<void> _load() async {
    try {
      final fetched = await _repository.fetchAll();
      _events
        ..clear()
        ..addAll(fetched);
      _loadError = null;
    } catch (error) {
      // Anything already in the feed stays. A failed refresh should not empty
      // the applicant's notifications.
      _loadError = error;
    } finally {
      // In the `finally`, not the `try`: without it a thrown fetch left
      // `_isLoading` true for the rest of the session and the feed spun
      // forever, with the exception escaping unhandled on top.
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _load();

  // -- delivery ------------------------------------------------------------

  void updatePreferences(NotificationPreferences updated) {
    preferences = updated;
    notifyListeners();
  }

  /// Philippine Standard Time has no daylight saving, so quiet hours are a
  /// plain comparison against the device's local hour.
  bool isQuietHour(DateTime at) => at.hour >= 21 || at.hour < 7;

  /// Whether this event would actually reach the applicant as a push.
  ///
  /// A muted category or a quiet hour suppresses the push and never the feed
  /// entry: the applicant asked for fewer interruptions, not for the record to
  /// be withheld from them.
  bool shouldPush(NotificationType type, {required DateTime at}) {
    if (!preferences.pushNotifications) return false;
    if (!type.priority.pushesByDefault) return false;
    if (!preferences.allows(type.category)) return false;

    // A P1 whose deadline is imminent overrides quiet hours; nothing else does.
    if (isQuietHour(at) && type.priority != NotificationPriority.action) {
      return false;
    }
    return true;
  }

  /// Records an event. Returns it so callers can assert on delivery.
  NotificationEvent record(
    NotificationType type, {
    String? applicationId,
    String? applicationNumber,
    Map<String, String> payload = const {},
  }) {
    final now = _clock();
    final event = NotificationEvent(
      id: 'n-${now.microsecondsSinceEpoch}-${_events.length}',
      type: type,
      applicationId: applicationId,
      applicationNumber: applicationNumber,
      payload: payload,
      createdAt: now,
      pushSuppressed: !shouldPush(type, at: now),
    );
    _events.insert(0, event);
    notifyListeners();
    return event;
  }

  /// Records notifications the app derived for itself, skipping any whose
  /// condition is already in the feed.
  ///
  /// Returns how many were new. The evaluator runs on every load and keeps
  /// deriving a condition for as long as it holds, so the skip is what stands
  /// between an applicant and one identical entry per launch.
  int recordDerived(Iterable<DerivedNotification> derived) {
    final seen = {
      for (final event in _events)
        if (event.dedupeKey != null) event.dedupeKey!,
    };

    var added = 0;
    for (final item in derived) {
      if (seen.contains(item.dedupeKey)) continue;
      seen.add(item.dedupeKey);

      final now = _clock();
      _events.insert(
        0,
        NotificationEvent(
          id: 'n-${now.microsecondsSinceEpoch}-${_events.length}',
          type: item.type,
          applicationId: item.applicationId,
          applicationNumber: item.applicationNumber,
          payload: item.payload,
          createdAt: now,
          pushSuppressed: !shouldPush(item.type, at: now),
          dedupeKey: item.dedupeKey,
        ),
      );
      added++;
    }

    if (added > 0) notifyListeners();
    return added;
  }

  /// Convenience for non-application events such as registering a business.
  void addNotification({
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_outlined,
  }) {
    record(
      NotificationType.accountUpdate,
      payload: {'title': title, 'body': message},
    );
  }

  // -- state ---------------------------------------------------------------

  void markAsRead(String id) => _update(id, (e) => e.copyWith(readAt: _clock()));

  /// Marks everything read. Deliberately does **not** resolve anything: an
  /// outstanding P1 keeps its place in Needs your action and its badge.
  void markAllAsRead() {
    final now = _clock();
    var changed = false;
    for (var i = 0; i < _events.length; i++) {
      if (!_events[i].isRead) {
        _events[i] = _events[i].copyWith(readAt: now);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Clears an outstanding action once the underlying condition is dealt with.
  /// Called when the applicant actually resolves the thing, never on read.
  void resolve(String id) =>
      _update(id, (e) => e.copyWith(resolvedAt: _clock()));

  /// Resolves every outstanding action of [type] for one application — used
  /// when the condition clears server-side rather than per-notification.
  void resolveFor(String applicationId, NotificationType type) {
    final now = _clock();
    var changed = false;
    for (var i = 0; i < _events.length; i++) {
      final event = _events[i];
      if (event.applicationId == applicationId &&
          event.type == type &&
          !event.isResolved) {
        _events[i] = event.copyWith(resolvedAt: now);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void _update(String id, NotificationEvent Function(NotificationEvent) apply) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _events[index] = apply(_events[index]);
    notifyListeners();
  }
}
