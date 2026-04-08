import 'dart:developer' as developer;
import 'deezer_service.dart';
import '../models/music_track.dart';

class MoodMusicService {
  final DeezerService _deezerService = DeezerService();

  /// No-op initializer kept for API compatibility with the screen.
  Future<void> initialize() async {}

  /// Returns mood-matched tracks from Deezer, trying multiple queries
  /// in order from most specific to most generic until results are found.
  Future<List<MusicTrack>> getTracksForMood(String mood) async {
    final queries = _getSearchQueries(mood);

    for (final query in queries) {
      try {
        final tracks = await _deezerService.searchTracks(
          query: query,
          limit: 20,
        );
        if (tracks.isNotEmpty) return tracks;
      } catch (e) {
        developer.log('Deezer query "$query" failed: $e');
        continue;
      }
    }

    return [];
  }

  /// Get the Deezer web URL for a track.
  String getTrackUrl(String trackId) => _deezerService.getTrackUrl(trackId);

  /// Ordered search queries per mood — most specific first.
  List<String> _getSearchQueries(String mood) {
    switch (mood.toLowerCase()) {
      case 'sad':
        return [
          'happy upbeat feel good pop',
          'uplifting pop songs',
          'feel good music',
          'happy pop hits',
        ];
      case 'anxious':
        return [
          'calm relaxing acoustic chill',
          'peaceful meditation ambient',
          'relaxing music',
          'chill acoustic',
        ];
      case 'tired':
        return [
          'energetic workout motivation',
          'upbeat dance songs',
          'high energy pop',
          'workout hits',
        ];
      case 'calm':
        return [
          'feel good indie pop positive',
          'positive happy indie',
          'feel good songs',
          'indie pop hits',
        ];
      default:
        return [
          'happy positive pop',
          'top pop hits',
          'feel good music',
        ];
    }
  }

  /// Human-readable description shown under the mood header.
  String getMoodDescription(String mood) {
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
}
