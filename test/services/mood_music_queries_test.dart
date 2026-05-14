import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/mood_music_queries.dart';

void main() {
  group('moodMusicSearchQueries', () {
    test('sad mood returns uplifting queries first', () {
      final q = moodMusicSearchQueries('Sad');
      expect(q.first, 'happy upbeat pop');
      expect(q, contains('positive pop'));
    });

    test('anxious mood returns calm queries', () {
      final q = moodMusicSearchQueries('ANXIOUS');
      expect(q.first, 'calm relaxing acoustic');
    });

    test('tired mood returns energetic queries', () {
      final q = moodMusicSearchQueries('tired');
      expect(q.first, 'energetic upbeat dance');
    });

    test('calm mood returns indie-positive queries', () {
      final q = moodMusicSearchQueries('calm');
      expect(q.first, 'positive indie happy');
    });

    test('unknown mood returns generic pop queries', () {
      final q = moodMusicSearchQueries('confused');
      expect(q.first, 'happy positive pop');
    });
  });

  group('moodMusicDescription', () {
    test('matches known moods', () {
      expect(
        moodMusicDescription('sad'),
        'Uplifting & energetic music to boost your spirits',
      );
      expect(
        moodMusicDescription('anxious'),
        'Calming & soothing music to ease your mind',
      );
      expect(
        moodMusicDescription('tired'),
        'Energizing & motivating music to wake you up',
      );
      expect(
        moodMusicDescription('calm'),
        'Positive & feel-good music to enhance your mood',
      );
    });

    test('default description for other moods', () {
      expect(moodMusicDescription('x'), 'Music recommendations for you');
    });
  });
}
