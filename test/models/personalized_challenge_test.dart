import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/gemini_challenges_service.dart';

void main() {
  group('PersonalizedChallenge', () {
    test('toMap serializes fields', () {
      const c = PersonalizedChallenge(
        title: 'Read one page',
        icon: '📖',
        isDone: true,
      );
      expect(c.toMap(), {
        'title': 'Read one page',
        'icon': '📖',
        'isDone': true,
      });
    });

    test('fromMap uses defaults for missing keys', () {
      final c = PersonalizedChallenge.fromMap({});
      expect(c.title, 'Complete a task');
      expect(c.icon, '📝');
      expect(c.isDone, false);
    });

    test('fromMap reads explicit values', () {
      final c = PersonalizedChallenge.fromMap({
        'title': 'T',
        'icon': '⭐',
        'isDone': true,
      });
      expect(c.title, 'T');
      expect(c.icon, '⭐');
      expect(c.isDone, true);
    });
  });
}
