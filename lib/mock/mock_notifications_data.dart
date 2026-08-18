import '../core/models/notification_event.dart';

/// Seed notifications, built fresh on every call so separate provider
/// instances never share state.
///
/// Deliberately includes one outstanding P1 (a Letter of Instruction) so the
/// resolve-versus-read behaviour is exercised the moment the app is opened
/// rather than only under test.
List<NotificationEvent> buildMockNotifications() {
  final now = DateTime.now();
  const ref = 'E-BPCO-2026-000145';
  const applicationId = 'app-seed-1';

  return [
    NotificationEvent(
      id: 'n1',
      type: NotificationType.letterOfInstructionIssued,
      applicationId: applicationId,
      applicationNumber: ref,
      payload: const {'count': '2'},
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    NotificationEvent(
      id: 'n2',
      type: NotificationType.evaluationStagePassed,
      applicationId: applicationId,
      applicationNumber: ref,
      payload: const {'stage': 'Zoning'},
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    NotificationEvent(
      id: 'n3',
      type: NotificationType.receivedByObo,
      applicationId: applicationId,
      applicationNumber: ref,
      createdAt: now.subtract(const Duration(days: 1)),
      readAt: now.subtract(const Duration(hours: 20)),
    ),
    NotificationEvent(
      id: 'n4',
      type: NotificationType.documentVerificationStarted,
      applicationId: applicationId,
      applicationNumber: ref,
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      readAt: now.subtract(const Duration(days: 1)),
    ),
    NotificationEvent(
      id: 'n5',
      type: NotificationType.applicationSubmitted,
      applicationId: applicationId,
      applicationNumber: ref,
      payload: const {'permitType': 'New Construction'},
      createdAt: now.subtract(const Duration(days: 3)),
      readAt: now.subtract(const Duration(days: 3)),
    ),
  ];
}
