// Ordered Jamendo search queries per mood — most specific first.
List<String> moodMusicSearchQueries(String mood) {
  switch (mood.toLowerCase()) {
    case 'sad':
      return [
        'happy upbeat pop',
        'uplifting pop',
        'feel good',
        'positive pop',
      ];
    case 'anxious':
      return [
        'calm relaxing acoustic',
        'peaceful ambient meditation',
        'relaxing chill',
        'soft acoustic',
      ];
    case 'tired':
      return [
        'energetic upbeat dance',
        'workout motivation',
        'high energy',
        'dance electronic',
      ];
    case 'calm':
      return [
        'positive indie happy',
        'feel good indie',
        'uplifting indie',
        'indie pop',
      ];
    default:
      return [
        'happy positive pop',
        'feel good',
        'pop hits',
      ];
  }
}

/// Human-readable description shown under the mood header on Music For You.
String moodMusicDescription(String mood) {
  switch (mood.toLowerCase()) {
    case 'sad':
      return 'Uplifting & energetic music to boost your spirits';
    case 'anxious':
      return 'Calming & soothing music to ease your mind';
    case 'tired':
      return 'Energizing & motivating music to wake you up';
    case 'calm':
      return 'Positive & feel-good music to enhance your mood';
    default:
      return 'Music recommendations for you';
  }
}
