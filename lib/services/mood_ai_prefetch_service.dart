import 'gemini_challenges_service.dart';
import 'gemini_tips_service.dart';

/// Warms on-device caches for recovery tips and personalized challenges as soon
/// as today’s mood is known, so those screens usually show content without waiting
/// on Gemini.
class MoodAiPrefetchService {
  MoodAiPrefetchService._();
  static final MoodAiPrefetchService instance = MoodAiPrefetchService._();

  void prefetch({
    required String mood,
    required String sleepHours,
    required List<String> goals,
  }) {
    final m = mood.trim().toLowerCase();
    if (m.isEmpty) return;
    Future<void>(() async {
      try {
        await Future.wait([
          GeminiTipsService().getTips(
            mood: m,
            sleepHours: sleepHours,
            goals: goals,
          ),
          GeminiChallengesService().getTodayChallengesWithStatus(
            mood: m,
            sleepHours: sleepHours,
            goals: goals,
          ),
        ]);
      } catch (_) {
        // Best-effort; detail screens will load or show errors.
      }
    });
  }
}
