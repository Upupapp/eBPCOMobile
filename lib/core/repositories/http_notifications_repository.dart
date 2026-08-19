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

  static String _wireNameOf(String constant) =>
      constant.replaceAllMapped(RegExp('(?<!^)([A-Z])'), (m) => '-${m[1]}').toLowerCase();

  @override
  Future<List<NotificationEvent>> fetchAll() async {
    final rows = await _api.getList('/notifications');
    final events = [
      for (final row in rows)
        if (row is Map<String, dynamic>)
          _parse(row)
        else
          throw const ApiException(ApiFailure.malformed, 'expected notification objects'),
    ];
    // Newest first, whatever order the server sent: the feed is read top-down
    // and an out-of-order list reads as a bug in the office, not the app.
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return events;
  }

  NotificationEvent _parse(Map<String, dynamic> json) {
    final rawType = json['type'];
    if (rawType is! String) {
      throw const ApiException(ApiFailure.malformed, 'notification has no type');
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
      createdAt: _dateTime(json, 'createdAt'),
      readAt: _dateTimeOrNull(json, 'readAt'),
      resolvedAt: _dateTimeOrNull(json, 'resolvedAt'),
    );
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw ApiException(ApiFailure.malformed, 'missing required string "$key"');
  }

  static DateTime _dateTime(Map<String, dynamic> json, String key) {
    final parsed = _dateTimeOrNull(json, key);
    if (parsed == null) {
      throw ApiException(ApiFailure.malformed, 'missing or unparseable date "$key"');
    }
    return parsed;
  }

  static DateTime? _dateTimeOrNull(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
