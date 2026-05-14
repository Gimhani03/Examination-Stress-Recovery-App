import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/music_track.dart';

void main() {
  group('MusicTrack.fromJamendoMap', () {
    test('maps full Jamendo item', () {
      final t = MusicTrack.fromJamendoMap({
        'id': 123,
        'name': 'Song',
        'artist_name': 'Artist',
        'album_image': 'https://img',
        'audio': 'https://audio',
        'shareurl': 'https://share',
      });
      expect(t.id, '123');
      expect(t.title, 'Song');
      expect(t.artist, 'Artist');
      expect(t.albumArt, 'https://img');
      expect(t.previewUrl, 'https://audio');
      expect(t.externalUrl, 'https://share');
    });

    test('defaults title artist and external url when missing', () {
      final t = MusicTrack.fromJamendoMap({'id': 99});
      expect(t.id, '99');
      expect(t.title, 'Unknown Title');
      expect(t.artist, 'Unknown Artist');
      expect(t.albumArt, isNull);
      expect(t.previewUrl, isNull);
      expect(t.externalUrl, 'https://www.jamendo.com/track/99');
    });
  });
}
