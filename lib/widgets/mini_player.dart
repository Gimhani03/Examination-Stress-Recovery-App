import 'package:flutter/material.dart';
import '../services/music_player_service.dart';

/// A compact player bar shown above the bottom nav when music is playing.
/// Uses the singleton MusicPlayerService so it reflects the current state
/// across all screens.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MusicPlayerService.instance,
      builder: (context, _) {
        final player = MusicPlayerService.instance;

        // Only render when a track is loaded
        if (player.currentTrack == null) return const SizedBox.shrink();

        final track = player.currentTrack!;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0277BD), Color(0xFF29B6F6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x660288D1),
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, posSnap) {
                  return StreamBuilder<Duration?>(
                    stream: player.durationStream,
                    builder: (context, durSnap) {
                      final position =
                          posSnap.data ?? Duration.zero;
                      final duration =
                          durSnap.data ?? Duration.zero;
                      final progress = duration.inMilliseconds > 0
                          ? (position.inMilliseconds /
                                  duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0.0;

                      return LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                        minHeight: 3,
                      );
                    },
                  );
                },
              ),

              // Controls row
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: track.albumArt != null
                          ? Image.network(
                              track.albumArt!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    const SizedBox(width: 12),

                    // Track info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.artist,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Previous
                    IconButton(
                      icon: const Icon(Icons.skip_previous,
                          color: Colors.white, size: 24),
                      onPressed: player.playlist.length > 1
                          ? () => player.playPrevious()
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),

                    // Play / Pause
                    GestureDetector(
                      onTap: () {
                        if (player.isPlaying) {
                          player.pause();
                        } else {
                          player.resume();
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 1.5),
                        ),
                        child: player.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                player.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Next
                    IconButton(
                      icon: const Icon(Icons.skip_next,
                          color: Colors.white, size: 24),
                      onPressed: player.playlist.length > 1
                          ? () => player.playNext()
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),

                    // Stop / dismiss
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 20),
                      onPressed: () => player.stop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.white.withValues(alpha: 0.2),
      child: const Icon(Icons.music_note, color: Colors.white, size: 20),
    );
  }
}
