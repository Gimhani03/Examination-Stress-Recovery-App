import 'dart:developer' as developer;
import 'jamendo_service.dart';
import 'mood_music_queries.dart';
import '../models/music_track.dart';

class MoodMusicService {
  final JamendoService _jamendoService = JamendoService();

  /// No-op initializer kept for API compatibility with the screen.
  Future<void> initialize() async {}

  /// Returns mood-matched tracks from Jamendo, trying multiple queries
  /// in order from most specific to most generic until results are found.
  Future<List<MusicTrack>> getTracksForMood(String mood) async {
    final queries = moodMusicSearchQueries(mood);

    for (final query in queries) {
      try {
        final tracks = await _jamendoService.searchTracks(
          query: query,
          limit: 20,
        );
        if (tracks.isNotEmpty) return tracks;
      } catch (e) {
        developer.log('Jamendo query "$query" failed: $e');
        continue;
      }
    }

    return [];
  }

  /// Human-readable description shown under the mood header.
  String getMoodDescription(String mood) => moodMusicDescription(mood);
}
