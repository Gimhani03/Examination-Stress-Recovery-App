import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/mood_music_service.dart';
import 'services/music_player_service.dart';
import 'models/music_track.dart';
import 'mood_flow_theme.dart';

/// Matches homepage “Music For You” card blues.
const Color _kMusicBlueAccent = Color(0xFF1D4ED8);
const Color _kMusicBlueSolid = Color(0xFF2563EB);
const Color _kMusicBlueSoft = Color(0xFFBFDBFE);
const Color _kMusicBlueWash = Color(0xFFDBEAFE);

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
          const SnackBar(content: Text('Could not open Jamendo.')),
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
      backgroundColor: kMoodFlowBg,
      appBar: AppBar(
        backgroundColor: kMoodFlowBg,
        elevation: 0,
        leading: IconButton(
          iconSize: 26,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Music For You',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -0.4,
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEFF6FF),
                    Color(0xFFDBEAFE),
                  ],
                ),
                borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: moodFlowNeoShadows(),
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
        child: CircularProgressIndicator(color: kMoodFlowTealAccent),
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
                  color: _kMusicBlueSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kMusicBlueSolid, width: 2),
                ),
                child: const Icon(
                  Icons.music_off,
                  size: 50,
                  color: _kMusicBlueAccent,
                ),
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
                icon: const Icon(Icons.refresh, color: Colors.black87),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kMusicBlueSoft,
                  foregroundColor: _kMusicBlueAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
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
        color: isCurrentTrack ? _kMusicBlueWash : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildAlbumArt(track),
        title: Text(
          track.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isCurrentTrack ? _kMusicBlueAccent : Colors.black87,
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
                        size: 14, color: _kMusicBlueAccent),
                    const SizedBox(width: 4),
                    Text(
                      'Now playing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kMusicBlueAccent,
                        fontWeight: FontWeight.w600,
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
            Material(
              color: _kMusicBlueSoft,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _player.isLoading && isCurrentTrack
                    ? null
                    : () => _player.togglePlayPause(index),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: _player.isLoading && isCurrentTrack
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black87,
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.black87,
                          size: 28,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _kMusicBlueSoft,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openTrack(track.externalUrl),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.open_in_new_rounded,
                    color: _kMusicBlueAccent,
                    size: 22,
                  ),
                ),
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
        color: _kMusicBlueWash,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: _kMusicBlueAccent,
        size: 30,
      ),
    );
  }
}
