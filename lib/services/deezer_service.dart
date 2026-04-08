import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/music_track.dart';

/// Deezer public API — no API key required, free, no OAuth.
/// Docs: https://developers.deezer.com/api
class DeezerService {
  static const String _baseUrl = 'https://api.deezer.com';

  /// Search tracks by query string. Returns up to [limit] results.
  Future<List<MusicTrack>> searchTracks({
    required String query,
    int limit = 20,
  }) async {
    developer.log('Deezer search: "$query"');

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': query,
      'limit': limit.toString(),
      'order': 'RANKING',
    });

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception(
          'Deezer API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];

    final tracks = items
        .map((item) =>
            MusicTrack.fromJson(item as Map<String, dynamic>))
        .toList();

    developer.log('Deezer returned ${tracks.length} tracks');
    return tracks;
  }

  /// Get the Deezer web URL for a track.
  String getTrackUrl(String trackId) {
    return 'https://www.deezer.com/track/$trackId';
  }
}
