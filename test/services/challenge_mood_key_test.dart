import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/challenge_mood_key.dart';

void main() {
  group('normalizeChallengeMoodKey', () {
    test('empty or whitespace becomes calm', () {
      expect(normalizeChallengeMoodKey(''), 'calm');
      expect(normalizeChallengeMoodKey('   '), 'calm');
    });

    test('trims and lowercases', () {
      expect(normalizeChallengeMoodKey('  Anxious  '), 'anxious');
    });

    test('preserves normalized mood string', () {
      expect(normalizeChallengeMoodKey('sad'), 'sad');
    });
  });
}
