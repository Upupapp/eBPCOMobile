import 'notification_event.dart';

/// Which notification categories the applicant wants pushed.
///
/// These genuinely gate delivery — see NotificationsProvider.shouldPush. A
/// preferences screen whose switches change nothing is worse than no
/// preferences screen, because it teaches the applicant that the app's
/// controls are decorative.
class NotificationPreferences {
  final bool applicationUpdates;
  final bool paymentNotifications;
  final bool permitStatusUpdates;
  final bool documentReminders;
  final bool systemAnnouncements;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;

  const NotificationPreferences({
    this.applicationUpdates = true,
    this.paymentNotifications = true,
    this.permitStatusUpdates = true,
    this.documentReminders = true,
    this.systemAnnouncements = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.pushNotifications = true,
  });

  /// Whether events in [category] may push. Account events are not mutable
  /// from this screen and always follow the master push switch.
  bool allows(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.applicationUpdates:
        return applicationUpdates;
      case NotificationCategory.payments:
        return paymentNotifications;
      case NotificationCategory.permitStatus:
        return permitStatusUpdates;
      case NotificationCategory.documentReminders:
        return documentReminders;
      case NotificationCategory.appointments:
        return applicationUpdates;
      case NotificationCategory.account:
        return systemAnnouncements;
    }
  }

  NotificationPreferences copyWith({
    bool? applicationUpdates,
    bool? paymentNotifications,
    bool? permitStatusUpdates,
    bool? documentReminders,
    bool? systemAnnouncements,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
  }) {
    return NotificationPreferences(
      applicationUpdates: applicationUpdates ?? this.applicationUpdates,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      permitStatusUpdates: permitStatusUpdates ?? this.permitStatusUpdates,
      documentReminders: documentReminders ?? this.documentReminders,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}
