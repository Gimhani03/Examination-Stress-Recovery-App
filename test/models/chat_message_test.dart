import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/chat_message.dart';

void main() {
  final fixedTime = DateTime.utc(2025, 4, 1, 12, 30);

  group('ChatMessage.toMap', () {
    test('serializes fields for storage', () {
      final m = ChatMessage(
        id: 'm1',
        role: 'user',
        content: 'Hello',
        timestamp: fixedTime,
        isError: true,
      ).toMap();

      expect(m['id'], 'm1');
      expect(m['role'], 'user');
      expect(m['content'], 'Hello');
      expect(m['timestamp'], fixedTime.toIso8601String());
      expect(m['is_error'], true);
    });
  });

  group('ChatMessage.fromMap', () {
    test('parses stored map', () {
      final msg = ChatMessage.fromMap({
        'id': 'x',
        'role': 'assistant',
        'content': 'Hi',
        'timestamp': '2025-04-01T12:30:00.000Z',
        'is_error': false,
      });
      expect(msg.id, 'x');
      expect(msg.role, 'assistant');
      expect(msg.content, 'Hi');
      expect(msg.timestamp, DateTime.parse('2025-04-01T12:30:00.000Z'));
      expect(msg.isError, false);
    });

    test('defaults when keys missing', () {
      final msg = ChatMessage.fromMap({});
      expect(msg.id, '');
      expect(msg.role, 'user');
      expect(msg.content, '');
      expect(msg.isError, false);
    });

    test('accepts camelCase isError from map', () {
      final msg = ChatMessage.fromMap({
        'id': '1',
        'role': 'user',
        'content': 'c',
        'timestamp': fixedTime.toIso8601String(),
        'isError': true,
      });
      expect(msg.isError, true);
    });
  });

  group('ChatMessage.copyWith', () {
    test('overrides selected fields', () {
      final a = ChatMessage(
        id: '1',
        role: 'user',
        content: 'a',
        timestamp: fixedTime,
      );
      final b = a.copyWith(content: 'b', isError: true);
      expect(b.id, '1');
      expect(b.role, 'user');
      expect(b.content, 'b');
      expect(b.timestamp, fixedTime);
      expect(b.isError, true);
    });
  });
}
