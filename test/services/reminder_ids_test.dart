import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/reminder_service.dart';

void main() {
  group('ReminderIds', () {
    test('daily ids are stable constants', () {
      expect(ReminderIds.moodDaily, 101);
      expect(ReminderIds.studyDaily, 102);
      expect(ReminderIds.breatheDaily, 103);
      expect(ReminderIds.recoveryDaily, 104);
      expect(ReminderIds.challengesDaily, 105);
    });

    test('event notification ids are deterministic from eventId', () {
      const id = 'evt-uuid-1';
      expect(ReminderIds.eventDayBefore(id), ReminderIds.eventDayBefore(id));
      expect(ReminderIds.eventThreeHours(id), ReminderIds.eventThreeHours(id));
    });

    test('day-before and three-hours ids differ for same event', () {
      const id = 'same-event';
      expect(
        ReminderIds.eventDayBefore(id),
        isNot(ReminderIds.eventThreeHours(id)),
      );
    });

    test('uses lower 22 bits of hash so ids stay in expected ranges', () {
      const id = 'any-string';
      final day = ReminderIds.eventDayBefore(id);
      final three = ReminderIds.eventThreeHours(id);
      expect(day, greaterThanOrEqualTo(1_000_000));
      expect(day, lessThan(1_000_000 + 0x400000));
      expect(three, greaterThanOrEqualTo(4_000_000));
      expect(three, lessThan(4_000_000 + 0x400000));
    });
  });
}
