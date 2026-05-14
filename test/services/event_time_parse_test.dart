import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/event_time_parse.dart';

void main() {
  group('parseEventDateLocal', () {
    test('returns null for null or empty', () {
      expect(parseEventDateLocal(null), isNull);
      expect(parseEventDateLocal(''), isNull);
      expect(parseEventDateLocal('   '), isNull);
    });

    test('parses YYYY-MM-DD as local calendar date', () {
      expect(
        parseEventDateLocal('2025-03-15'),
        DateTime(2025, 3, 15),
      );
    });

    test('uses date part only before T for ISO strings', () {
      expect(
        parseEventDateLocal('2025-03-15T22:00:00.000Z'),
        DateTime(2025, 3, 15),
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        parseEventDateLocal('  2024-01-02  '),
        DateTime(2024, 1, 2),
      );
    });

    test('returns null for unparseable input', () {
      expect(parseEventDateLocal('not-a-date'), isNull);
      expect(parseEventDateLocal('2025-ab-01'), isNull);
    });
  });

  group('parseEventTimeToLocalDateTime', () {
    final eventDay = DateTime(2025, 6, 10);

    test('returns null for empty, any time, or dash-only remainder', () {
      expect(parseEventTimeToLocalDateTime('', eventDay), isNull);
      expect(parseEventTimeToLocalDateTime('  ', eventDay), isNull);
      expect(parseEventTimeToLocalDateTime('Any Time', eventDay), isNull);
      expect(parseEventTimeToLocalDateTime('any time', eventDay), isNull);
      expect(parseEventTimeToLocalDateTime('—', eventDay), isNull);
    });

    test('parses plain 24h HH:mm', () {
      expect(
        parseEventTimeToLocalDateTime('14:30', eventDay),
        DateTime(2025, 6, 10, 14, 30),
      );
      expect(
        parseEventTimeToLocalDateTime('9:05', eventDay),
        DateTime(2025, 6, 10, 9, 5),
      );
    });

    test('returns null for strings no format can parse', () {
      expect(parseEventTimeToLocalDateTime('not-a-time', eventDay), isNull);
      expect(parseEventTimeToLocalDateTime('soon', eventDay), isNull);
    });

    test('parses English AM/PM via DateFormat', () {
      expect(
        parseEventTimeToLocalDateTime('1:00 PM', eventDay),
        DateTime(2025, 6, 10, 13, 0),
      );
      expect(
        parseEventTimeToLocalDateTime('9:30 AM', eventDay),
        DateTime(2025, 6, 10, 9, 30),
      );
    });

    test('strips note after em dash or hyphen', () {
      expect(
        parseEventTimeToLocalDateTime('9:00 AM — leave empty', eventDay),
        DateTime(2025, 6, 10, 9, 0),
      );
      expect(
        parseEventTimeToLocalDateTime('10:15 AM - room A', eventDay),
        DateTime(2025, 6, 10, 10, 15),
      );
    });
  });

  group('friendlyMoodLabel', () {
    test('empty or null becomes default phrase', () {
      expect(friendlyMoodLabel(null), 'your last');
      expect(friendlyMoodLabel(''), 'your last');
      expect(friendlyMoodLabel('   '), 'your last');
    });

    test('single letter uppercases', () {
      expect(friendlyMoodLabel('a'), 'A');
      expect(friendlyMoodLabel('B'), 'B');
    });

    test('capitalizes first letter of word', () {
      expect(friendlyMoodLabel('anxious'), 'Anxious');
      expect(friendlyMoodLabel('CALM'), 'Calm');
    });
  });
}
