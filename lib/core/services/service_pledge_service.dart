import '../models/permit_classification.dart';
import 'holiday_calendar.dart';

/// The service pledge for one application: when the LGU has undertaken to
/// finish, how much of that time has been used, and whether it has run out.
class ServicePledge {
  /// First working day of processing — the working day on or after filing.
  final DateTime firstWorkingDay;

  /// The working day by which the LGU has pledged to act.
  final DateTime pledgedCompletionDate;

  final PermitClassification classification;

  /// Working days consumed so far, counting [firstWorkingDay] as day 1 and
  /// capped at the prescribed total.
  final int workingDaysElapsed;

  /// Working days left before the pledge lapses. Zero once it has.
  final int workingDaysRemaining;

  /// True once the pledged date has passed without release.
  final bool hasLapsed;

  /// True when the holiday calendar has no declared-holiday data for some year
  /// this pledge spans, so the dates are a best effort rather than exact. The
  /// UI must caveat rather than assert when this is set.
  final bool calendarIncomplete;

  const ServicePledge({
    required this.firstWorkingDay,
    required this.pledgedCompletionDate,
    required this.classification,
    required this.workingDaysElapsed,
    required this.workingDaysRemaining,
    required this.hasLapsed,
    required this.calendarIncomplete,
  });

  /// True when the pledge is close enough to warrant an amber treatment.
  bool get isDueSoon => !hasLapsed && workingDaysRemaining <= 2;
}

/// Computes RA 11032 service pledges in Philippine working days.
///
/// Every countdown in the app comes from here. Nothing computes processing
/// dates locally, so the holiday list, the day-counting convention, and the
/// lapse rule each exist in exactly one place.
///
/// Counting convention: RA 11032 measures processing from receipt of a
/// complete application. Filing on a non-working day therefore starts the
/// clock on the next working day, and that day is day 1 — a 3-working-day
/// simple application filed on a Friday is due the following Tuesday.
class ServicePledgeService {
  const ServicePledgeService({this.calendar = const PhilippineHolidayCalendar()});

  final HolidayCalendar calendar;

  bool isWorkingDay(DateTime date) {
    final day = _dateOnly(date);
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return false;
    }
    return !calendar.isDeclaredNonWorkingDay(day);
  }

  /// The working day on or after [from].
  DateTime nextWorkingDayOnOrAfter(DateTime from) {
    var cursor = _dateOnly(from);
    // Bounded so a pathological calendar can never spin forever.
    for (var i = 0; i < 400; i++) {
      if (isWorkingDay(cursor)) return cursor;
      cursor = cursor.add(const Duration(days: 1));
    }
    return cursor;
  }

  /// Working days in the inclusive range [start]–[end]. Zero when [end]
  /// precedes [start].
  int workingDaysBetween(DateTime start, DateTime end) {
    final from = _dateOnly(start);
    final to = _dateOnly(end);
    if (to.isBefore(from)) return 0;
    var count = 0;
    var cursor = from;
    while (!cursor.isAfter(to)) {
      if (isWorkingDay(cursor)) count++;
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }

  ServicePledge computeFor({
    required DateTime filedOn,
    required PermitClassification classification,
    required DateTime asOf,
  }) {
    final prescribed = classification.prescribedWorkingDays;
    final firstWorkingDay = nextWorkingDayOnOrAfter(filedOn);

    // Walk forward to the prescribed-th working day inclusive of day 1.
    var pledged = firstWorkingDay;
    var counted = 1;
    while (counted < prescribed) {
      pledged = nextWorkingDayOnOrAfter(pledged.add(const Duration(days: 1)));
      counted++;
    }

    final today = _dateOnly(asOf);
    final elapsedRaw = workingDaysBetween(firstWorkingDay, today);
    final elapsed = elapsedRaw > prescribed ? prescribed : elapsedRaw;
    final hasLapsed = today.isAfter(pledged);
    final remaining = hasLapsed ? 0 : prescribed - elapsed;

    return ServicePledge(
      firstWorkingDay: firstWorkingDay,
      pledgedCompletionDate: pledged,
      classification: classification,
      workingDaysElapsed: elapsed,
      workingDaysRemaining: remaining < 0 ? 0 : remaining,
      hasLapsed: hasLapsed,
      calendarIncomplete: !_hasCalendarDataAcross(firstWorkingDay, pledged),
    );
  }

  bool _hasCalendarDataAcross(DateTime start, DateTime end) {
    for (var year = start.year; year <= end.year; year++) {
      if (!calendar.hasDataFor(year)) return false;
    }
    return true;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
