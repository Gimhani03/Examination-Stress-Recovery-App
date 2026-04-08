class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String? albumArt;
  final String? previewUrl;
  final String deezerUrl;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArt,
    this.previewUrl,
    required this.deezerUrl,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Unknown Title',
      artist: (json['artist'] as Map<String, dynamic>?)?['name'] as String? ??
          'Unknown Artist',
      albumArt:
          (json['album'] as Map<String, dynamic>?)?['cover_medium'] as String?,
      previewUrl: json['preview'] as String?,
      deezerUrl: json['link'] as String? ??
          'https://www.deezer.com/track/${json['id']}',
    );
  }
}
