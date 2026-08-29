import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/notification_event.dart';
import 'notifications_repository.dart';

/// The applicant's feed, from the API.
///
/// The wire type is the kebab-case of this app's own [NotificationType]
/// constant, which is the reconciliation TAB 08 settled: the server adopted
/// this catalog rather than inventing a second one. So parsing is a mechanical
/// reversal of that derivation, and an unrecognised type throws — a
/// notification the app cannot name is one it cannot render an icon, a
/// category or a destination for, and showing a blank card would be worse than
/// failing.
class HttpNotificationsRepository implements NotificationsRepository {
  HttpNotificationsRepository(this._api);

  final ApiClient _api;

  static final Map<String, NotificationType> _byWireName = {
    for (final type in NotificationType.values) _wireNameOf(type.name): type,
  };

  static String _wireNameOf(String constant) => constant
      .replaceAllMapped(RegExp('(?<!^)([A-Z])'), (m) => '-${m[1]}')
      .toLowerCase();

  @override
  Future<List<NotificationEvent>> fetchAll() async {
    final rows = await _api.getList('/notifications');
    final events = [
      for (final row in rows)
        if (row is Map<String, dynamic>)
          _parse(row)
        else
          throw const ApiException(
            ApiFailure.malformed,
            'expected notification objects',
          ),
    ];
    // Newest first, whatever order the server sent: the feed is read top-down
    // and an out-of-order list reads as a bug in the office, not the app.
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return events;
  }

  NotificationEvent _parse(Map<String, dynamic> json) {
    final rawType = json['type'];
    if (rawType is! String) {
      throw const ApiException(
        ApiFailure.malformed,
        'notification has no type',
      );
    }
    final type = _byWireName[rawType];
    if (type == null) {
      throw ApiException(
        ApiFailure.malformed,
        'unknown notification type "$rawType" — the app and the server have drifted',
      );
    }

    return NotificationEvent(
      id: _string(json, 'id'),
      type: type,
      applicationId: json['applicationId'] as String?,
      // Every application-related body names its reference, because an
      // applicant with several permits in flight cannot otherwise tell which
      // one a notice is about. Dropping it made every one of them say "your
      // application".
      applicationNumber: json['applicationNumber'] as String?,
      // The template values. `NotificationEvent.body` reads permitType,
      // amount, remarks, dates and counts out of this, and falls back to
      // "your permit", "a few", "its deadline" when they are absent — so a
      // parser that never filled it turned every specific message into a
      // vague one. This is the field this audit existed to find.
      payload: _payload(json['payload']),
      createdAt: _dateTime(json, 'createdAt'),
      readAt: _dateTimeOrNull(json, 'readAt'),
      resolvedAt: _dateTimeOrNull(json, 'resolvedAt'),
    );
  }

  /// Template values, as strings.
  ///
  /// Coerced rather than rejected: the server sends counts and amounts as
  /// numbers, and the body interpolates everything into text anyway. A
  /// notification is not worth failing to load over a value's JSON type —
  /// [dedupeKey] and [pushSuppressed] are deliberately absent because both are
  /// local concerns, the first identifying a condition this app derived for
  /// itself and the second recording what this device decided about delivery.
  static Map<String, String> _payload(dynamic raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.value != null) '${entry.key}': '${entry.value}',
    };
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw ApiException(ApiFailure.malformed, 'missing required string "$key"');
  }

  static DateTime _dateTime(Map<String, dynamic> json, String key) {
    final parsed = _dateTimeOrNull(json, key);
    if (parsed == null) {
      throw ApiException(
        ApiFailure.malformed,
        'missing or unparseable date "$key"',
      );
    }
    return parsed;
  }

  static DateTime? _dateTimeOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
