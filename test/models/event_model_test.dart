import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/event_model.dart';

void main() {
  group('Event.fromDatabase', () {
    test('maps known fields and defaults missing time', () {
      final e = Event.fromDatabase({
        'id': 'evt-1',
        'user_id': 'user-1',
        'title': 'Exam',
        'event_date': '2025-08-20',
        'description': 'Final',
        'location': 'Hall A',
        'created_at': '2025-08-01T10:00:00.000Z',
        'updated_at': '2025-08-02T11:00:00.000Z',
      });

      expect(e.id, 'evt-1');
      expect(e.userId, 'user-1');
      expect(e.title, 'Exam');
      expect(e.eventDate, DateTime.parse('2025-08-20'));
      expect(e.time, 'Any time');
      expect(e.description, 'Final');
      expect(e.location, 'Hall A');
      expect(e.createdAt, DateTime.parse('2025-08-01T10:00:00.000Z'));
      expect(e.updatedAt, DateTime.parse('2025-08-02T11:00:00.000Z'));
    });

    test('uses explicit time when present', () {
      final e = Event.fromDatabase({
        'user_id': 'u',
        'title': 'T',
        'event_date': '2025-01-01',
        'time': '2:00 PM',
      });
      expect(e.time, '2:00 PM');
    });
  });

  group('Event.toDatabase', () {
    test('round-trips core fields with YYYY-MM-DD date', () {
      final created = DateTime.utc(2025, 5, 1, 8, 0);
      final e = Event(
        id: 'id-1',
        userId: 'uid',
        title: 'Title',
        eventDate: DateTime(2025, 12, 3),
        time: 'Morning',
        description: 'D',
        location: 'L',
        createdAt: created,
        updatedAt: created,
      );

      final m = e.toDatabase();
      expect(m['id'], 'id-1');
      expect(m['user_id'], 'uid');
      expect(m['title'], 'Title');
      expect(m['event_date'], '2025-12-03');
      expect(m['time'], 'Morning');
      expect(m['description'], 'D');
      expect(m['location'], 'L');
      expect(m['created_at'], created.toIso8601String());
      expect(m['updated_at'], created.toIso8601String());
    });

    test('omits id when null', () {
      final e = Event(
        userId: 'u',
        title: 'T',
        eventDate: DateTime(2025, 1, 2),
        time: 'Any time',
      );
      final m = e.toDatabase();
      expect(m.containsKey('id'), isFalse);
      expect(m.containsKey('created_at'), isFalse);
      expect(m.containsKey('updated_at'), isFalse);
    });
  });

  group('Event.copyWith', () {
    test('replaces only provided fields', () {
      final e = Event(
        userId: 'u',
        title: 'Old',
        eventDate: DateTime(2025, 1, 1),
        time: '10:00',
      );
      final next = e.copyWith(title: 'New', time: '11:00');
      expect(next.userId, 'u');
      expect(next.title, 'New');
      expect(next.eventDate, DateTime(2025, 1, 1));
      expect(next.time, '11:00');
    });
  });

  group('Event equality', () {
    test('same id and core fields are equal', () {
      final a = Event(
        id: '1',
        userId: 'u',
        title: 'T',
        eventDate: DateTime(2025, 1, 1),
        time: 'Any time',
        description: 'd',
        location: 'l',
      );
      final b = Event(
        id: '1',
        userId: 'u',
        title: 'T',
        eventDate: DateTime(2025, 1, 1),
        time: 'Any time',
        description: 'd',
        location: 'l',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when title changes', () {
      final a = Event(
        id: '1',
        userId: 'u',
        title: 'T',
        eventDate: DateTime(2025, 1, 1),
        time: 'Any time',
      );
      final b = a.copyWith(title: 'Other');
      expect(a == b, isFalse);
    });
  });
}
