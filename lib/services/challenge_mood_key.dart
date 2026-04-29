// Normalizes free-text mood for challenge cache keys and history.
String normalizeChallengeMoodKey(String mood) {
  final t = mood.trim().toLowerCase();
  if (t.isEmpty) return 'calm';
  return t;
}
