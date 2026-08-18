import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_user_app/core/models/permit_classification.dart';
import 'package:ebpco_user_app/core/services/holiday_calendar.dart';
import 'package:ebpco_user_app/core/services/service_pledge_service.dart';

/// A calendar with a single declared holiday, for isolating holiday handling
/// from weekend handling.
class _SingleHolidayCalendar extends HolidayCalendar {
  const _SingleHolidayCalendar(this.month, this.day);
  final int month;
  final int day;

  @override
  bool isDeclaredNonWorkingDay(DateTime date) =>
      date.month == month && date.day == day;

  @override
  bool hasDataFor(int year) => true;
}

void main() {
  const weekendsOnly = ServicePledgeService(calendar: WeekendsOnlyCalendar());
  const philippines = ServicePledgeService();

  group('working-day arithmetic', () {
    test('a simple application filed Monday is due Wednesday', () {
      // Mon 2 Feb 2026 → day 1 Mon, day 2 Tue, day 3 Wed.
      final pledge = weekendsOnly.computeFor(
        filedOn: DateTime(2026, 2, 2),
        classification: PermitClassification.simple,
        asOf: DateTime(2026, 2, 2),
      );

      expect(pledge.firstWorkingDay, DateTime(2026, 2, 2));
      expect(pledge.pledgedCompletionDate, DateTime(2026, 2, 4));
      expect(pledge.workingDaysElapsed, 1);
      expect(pledge.workingDaysRemaining, 2);
      expect(pledge.hasLapsed, isFalse);
    });

    test('a simple application filed Friday skips the weekend', () {
      // Fri 6 Feb 2026 → day 1 Fri, day 2 Mon 9th, day 3 Tue 10th.
      final pledge = weekendsOnly.computeFor(
        filedOn: DateTime(2026, 2, 6),
        classification: PermitClassification.simple,
        asOf: DateTime(2026, 2, 6),
      );

      expect(pledge.pledgedCompletionDate, DateTime(2026, 2, 10));
    });

    test('filing on a Saturday starts the clock on Monday', () {
      // Sat 7 Feb 2026 → processing starts Mon 9th, which is day 1.
      final pledge = weekendsOnly.computeFor(
        filedOn: DateTime(2026, 2, 7),
        classification: PermitClassification.simple,
        asOf: DateTime(2026, 2, 7),
      );

      expect(pledge.firstWorkingDay, DateTime(2026, 2, 9));
      expect(pledge.pledgedCompletionDate, DateTime(2026, 2, 11));
      // Filing day itself consumes none of the office's time.
      expect(pledge.workingDaysElapsed, 0);
      expect(pledge.workingDaysRemaining, 3);
    });

    test('a declared holiday pushes the pledged date out by a day', () {
      const withHoliday = ServicePledgeService(
        calendar: _SingleHolidayCalendar(2, 3),
      );
      // Tue 3 Feb declared non-working: day 1 Mon 2nd, day 2 Wed 4th,
      // day 3 Thu 5th.
      final pledge = withHoliday.computeFor(
        filedOn: DateTime(2026, 2, 2),
        classification: PermitClassification.simple,
        asOf: DateTime(2026, 2, 2),
      );

      expect(pledge.pledgedCompletionDate, DateTime(2026, 2, 5));
    });

    test('prescribed periods follow RA 11032', () {
      expect(PermitClassification.simple.prescribedWorkingDays, 3);
      expect(PermitClassification.complex.prescribedWorkingDays, 7);
      expect(PermitClassification.highlyTechnical.prescribedWorkingDays, 20);
    });
  });

  group('lapse handling', () {
    test('has not lapsed on the pledged date itself', () {
      final pledge = weekendsOnly.computeFor(
        filedOn: DateTime(2026, 2, 2),
        classification: PermitClassification.simple,
        asOf: DateTime(2026, 2, 4),
      );

      expect(pledge.hasLapsed, isFalse);
      expect(pledge.workingDaysRemaining, 0);
    });

    test('lapses the day after the pledged date', () {
      final pledge = weekendsOnly.computeFor(
        filedOn: DateTime(2026, 2, 2),
        classification: PermitClassification.simple,
        asOf: DateTime(2026, 2, 5),
      );

      expect(pledge.hasLapsed, isTrue);
      expect(pledge.workingDaysRemaining, 0);
    });

    test('elapsed days never exceed the prescribed period', () {
      final pledge = weekendsOnly.computeFor(
        filedOn: DateTime(2026, 2, 2),
        classification: PermitClassification.simple,
        asOf: DateTime(2026, 3, 2),
      );

      expect(pledge.workingDaysElapsed, 3);
    });

    test('is due soon within two working days of the pledge', () {
      final pledge = weekendsOnly.computeFor(
        filedOn: DateTime(2026, 2, 2),
        classification: PermitClassification.simple,
        asOf: DateTime(2026, 2, 3),
      );

      // Day 1 was Monday and day 2 is today, so only Wednesday is left.
      expect(pledge.workingDaysElapsed, 2);
      expect(pledge.workingDaysRemaining, 1);
      expect(pledge.isDueSoon, isTrue);
    });
  });

  group('Philippine holiday calendar', () {
    test('treats Proclamation No. 1006 dates as non-working', () {
      // A sample across regular holidays and special non-working days.
      for (final date in [
        DateTime(2026, 1, 1), // New Year's Day
        DateTime(2026, 4, 9), // Araw ng Kagitingan
        DateTime(2026, 6, 12), // Independence Day
        DateTime(2026, 8, 21), // Ninoy Aquino Day
        DateTime(2026, 8, 31), // National Heroes Day
        DateTime(2026, 11, 30), // Bonifacio Day
        DateTime(2026, 12, 25), // Christmas Day
        DateTime(2026, 12, 30), // Rizal Day
      ]) {
        expect(
          philippines.isWorkingDay(date),
          isFalse,
          reason: '$date is a declared non-working day in 2026',
        );
      }
    });

    test('25 February 2026 is a working day, not a holiday', () {
      // Proclamation No. 1006 declares it a special *working* day for the
      // 40th anniversary of the EDSA People Power Revolution. Treating it as
      // non-working would overstate the time the office has left.
      expect(philippines.isWorkingDay(DateTime(2026, 2, 25)), isTrue);
    });

    test('flags an incomplete calendar rather than guessing', () {
      // No proclamation data is held for 2030, so any pledge spanning it is
      // approximate and must say so.
      final pledge = philippines.computeFor(
        filedOn: DateTime(2030, 3, 4),
        classification: PermitClassification.simple,
        asOf: DateTime(2030, 3, 4),
      );

      expect(pledge.calendarIncomplete, isTrue);
    });

    test('does not flag a year it has data for', () {
      final pledge = philippines.computeFor(
        filedOn: DateTime(2026, 3, 4),
        classification: PermitClassification.simple,
        asOf: DateTime(2026, 3, 4),
      );

      expect(pledge.calendarIncomplete, isFalse);
    });
  });
}
