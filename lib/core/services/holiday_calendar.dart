/// Non-working days for Philippine working-day computations.
///
/// Kept behind an interface so tests can supply a deterministic calendar and
/// so next year's holidays can be loaded from a server without touching any
/// date arithmetic.
abstract class HolidayCalendar {
  const HolidayCalendar();

  /// Whether [date]'s calendar day is a nationwide non-working day. Weekends
  /// are handled by the pledge service, not here — this covers only declared
  /// holidays.
  bool isDeclaredNonWorkingDay(DateTime date);

  /// Whether declared-holiday data is on hand for [year]. Working-day maths
  /// over a year we have no data for silently under-counts holidays and so
  /// over-states how much time the office has left, which is why callers must
  /// be able to caveat the result rather than present it as fact.
  bool hasDataFor(int year);
}

/// Philippine regular holidays and special (non-working) days.
///
/// Populated from the annual Presidential Proclamation, because Philippine
/// holidays are not derivable from a fixed rule: movable feasts (Maundy
/// Thursday, Good Friday, Black Saturday) shift with the liturgical calendar,
/// National Heroes Day is the last Monday of August, and several dates are
/// added or moved by proclamation each year.
///
/// 2026 data is Proclamation No. 1006, s. 2026.
///
/// Two deliberate omissions:
///  * **Eidul Fitr and Eidul Adha** are excluded. Proclamation No. 1006 states
///    they are proclaimed separately once the dates are determined against the
///    Islamic (Hijri) calendar, so they are genuinely unknown at this point in
///    the year. They must be added by amendment when proclaimed.
///  * **25 February 2026** is *not* listed. The proclamation declares it a
///    special *working* day for the 40th anniversary of the EDSA People Power
///    Revolution, so it counts as a working day.
class PhilippineHolidayCalendar extends HolidayCalendar {
  const PhilippineHolidayCalendar();

  /// Declared non-working days keyed by year, as `MM-DD`.
  static const Map<int, Set<String>> _declared = {
    2026: {
      '01-01', // New Year's Day — regular
      '02-17', // Chinese New Year — special (non-working)
      '04-02', // Maundy Thursday — regular
      '04-03', // Good Friday — regular
      '04-04', // Black Saturday — special (non-working)
      '04-09', // Araw ng Kagitingan — regular
      '05-01', // Labor Day — regular
      '06-12', // Independence Day — regular
      '08-21', // Ninoy Aquino Day — special (non-working)
      '08-31', // National Heroes Day — regular
      '11-01', // All Saints' Day — special (non-working)
      '11-02', // All Souls' Day — special (non-working)
      '11-30', // Bonifacio Day — regular
      '12-08', // Feast of the Immaculate Conception — special (non-working)
      '12-24', // Christmas Eve — special (non-working)
      '12-25', // Christmas Day — regular
      '12-30', // Rizal Day — regular
      '12-31', // Last Day of the Year — special (non-working)
    },
  };

  @override
  bool isDeclaredNonWorkingDay(DateTime date) {
    final days = _declared[date.year];
    if (days == null) return false;
    final key =
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return days.contains(key);
  }

  @override
  bool hasDataFor(int year) => _declared.containsKey(year);
}

/// A calendar with no declared holidays — weekends only. Useful in tests that
/// assert pure working-day arithmetic without holiday interference.
class WeekendsOnlyCalendar extends HolidayCalendar {
  const WeekendsOnlyCalendar();

  @override
  bool isDeclaredNonWorkingDay(DateTime date) => false;

  @override
  bool hasDataFor(int year) => true;
}
