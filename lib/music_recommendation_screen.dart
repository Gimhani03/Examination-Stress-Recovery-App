import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/mood_music_service.dart';
import 'services/music_player_service.dart';
import 'models/music_track.dart';

class MusicRecommendationScreen extends StatefulWidget {
  final String mood;
  final String moodImage;

  const MusicRecommendationScreen({
    super.key,
    required this.mood,
    required this.moodImage,
  });

  @override
  State<MusicRecommendationScreen> createState() =>
      _MusicRecommendationScreenState();
}

class _MusicRecommendationScreenState
    extends State<MusicRecommendationScreen> {
  final MoodMusicService _musicService = MoodMusicService();

  // Use the singleton — survives navigation
  final MusicPlayerService _player = MusicPlayerService.instance;

  List<MusicTrack> _tracks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _musicService.initialize();
      final tracks = await _musicService.getTracksForMood(widget.mood);

      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
          if (tracks.isEmpty) {
            _errorMessage =
                'No recommendations available at the moment.\nPlease try again later.';
          } else {
            // Load the playlist into the singleton so it can auto-advance
            _player.setPlaylist(tracks);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to load music recommendations.\nPlease check your internet connection and try again.';
        });
      }
    }
  }

  Future<void> _openTrack(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Deezer.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDE9FE),
        elevation: 0,
        leadingWidth: 56,
        leading: Center(
          child: PhysicalModel(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            shadowColor: Colors.black38,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new,
                    color: Colors.black, size: 18),
              ),
            ),
          ),
        ),
        title: const Text(
          'Music For You',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mood header
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 248, 214, 254),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF0288D1), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(widget.moodImage, width: 50, height: 50),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feeling ${widget.mood.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _musicService.getMoodDescription(widget.mood),
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Track list — rebuilds whenever the singleton notifies
            Expanded(
              child: ListenableBuilder(
                listenable: _player,
                builder: (context, _) => _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0288D1)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8D6FE),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF0288D1), width: 2),
                ),
                child: const Icon(Icons.music_off,
                    size: 50, color: Color(0xFF0288D1)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Oops! No songs found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadRecommendations,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29B6F6),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_tracks.isEmpty) {
      return const Center(
        child: Text('No recommendations found',
            style: TextStyle(fontSize: 16, color: Colors.black54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _tracks.length,
      itemBuilder: (context, index) =>
          _buildTrackCard(index, _tracks[index]),
    );
  }

  Widget _buildTrackCard(int index, MusicTrack track) {
    final isCurrentTrack = _player.currentIndex == index;
    final isPlaying = isCurrentTrack && _player.isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentTrack
            ? const Color(0xFFE3F6FD)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTrack
              ? const Color(0xFF0288D1)
              : Colors.grey.shade300,
          width: isCurrentTrack ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 4),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildAlbumArt(track),
        title: Text(
          track.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isCurrentTrack
                ? const Color(0xFF0277BD)
                : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.artist,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isPlaying)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq,
                        size: 14, color: Color(0xFF0288D1)),
                    const SizedBox(width: 4),
                    Text(
                      'Now playing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF0288D1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play / Pause
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0288D1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: _player.isLoading && isCurrentTrack
                  ? const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                      ),
                      onPressed: () => _player.togglePlayPause(index),
                    ),
            ),
            const SizedBox(width: 8),
            // Open in Deezer
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF0288D1), width: 1),
              ),
              child: IconButton(
                icon: const Icon(Icons.open_in_new,
                    color: Color(0xFF0288D1), size: 20),
                onPressed: () => _openTrack(track.deezerUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt(MusicTrack track) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: track.albumArt != null
          ? Image.network(
              track.albumArt!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _albumArtPlaceholder(),
            )
          : _albumArtPlaceholder(),
    );
  }

  Widget _albumArtPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF29B6F6).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Color(0xFF0288D1), size: 30),
    );
  }
}
