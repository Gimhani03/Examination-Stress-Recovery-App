class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String? albumArt;
  final String? previewUrl;
  /// Web URL to open the track on the provider (e.g. Jamendo).
  final String externalUrl;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArt,
    this.previewUrl,
    required this.externalUrl,
  });

  /// One Jamendo API `results[]` item (`id`, `name`, `artist_name`, …).
  factory MusicTrack.fromJamendoMap(Map<String, dynamic> m) {
    final id = m['id'].toString();
    return MusicTrack(
      id: id,
      title: m['name'] as String? ?? 'Unknown Title',
      artist: m['artist_name'] as String? ?? 'Unknown Artist',
      albumArt: m['album_image'] as String?,
      previewUrl: m['audio'] as String?,
      externalUrl: m['shareurl'] as String? ?? 'https://www.jamendo.com/track/$id',
    );
  }
}
