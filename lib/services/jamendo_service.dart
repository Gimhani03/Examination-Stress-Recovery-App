import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

import '../models/music_track.dart';

/// Jamendo API v3 — Creative Commons music. Requires a free client ID.
/// https://developer.jamendo.com/v3.0/docs
class JamendoService {
  static const String _baseUrl = 'https://api.jamendo.com/v3.0';

  String get _clientId {
    final id = dotenv.env['JAMENDO_CLIENT_ID']?.trim();
    if (id == null || id.isEmpty) {
      throw StateError(
        'JAMENDO_CLIENT_ID is missing. Add it to .env (free key: https://devportal.jamendo.com/).',
      );
    }
    return id;
  }

  /// Search tracks by free-text [query]. Returns up to [limit] results.
  Future<List<MusicTrack>> searchTracks({
    required String query,
    int limit = 20,
  }) async {
    developer.log('Jamendo search: "$query"');

    final uri = Uri.parse('$_baseUrl/tracks/').replace(queryParameters: {
      'client_id': _clientId,
      'format': 'json',
      'search': query,
      'limit': limit.toString(),
      'order': 'relevance',
      'boost': 'popularity_total',
      'audioformat': 'mp32',
    });

    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception(
        'Jamendo API error: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['results'] as List<dynamic>? ?? [];

    final tracks = items
        .map((raw) => MusicTrack.fromJamendoMap(raw as Map<String, dynamic>))
        .toList();

    developer.log('Jamendo returned ${tracks.length} tracks');
    return tracks;
  }
}
