import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/music_track.dart';
import 'dart:developer' as developer;

/// Singleton service that owns the AudioPlayer for the entire app lifetime.
/// Music keeps playing when navigating between screens.
class MusicPlayerService extends ChangeNotifier {
  MusicPlayerService._internal() {
    _setupListeners();
  }

  static final MusicPlayerService instance = MusicPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();

  List<MusicTrack> playlist = [];
  MusicTrack? currentTrack;
  int? currentIndex;
  bool isPlaying = false;
  bool isLoading = false;

  AudioPlayer get player => _player;

  void _setupListeners() {
    _player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });
  }

  void _onTrackCompleted() {
    // Auto-advance to next track
    if (playlist.isNotEmpty && currentIndex != null) {
      final nextIndex = currentIndex! + 1;
      if (nextIndex < playlist.length) {
        playTrack(nextIndex);
      } else {
        currentIndex = null;
        currentTrack = null;
        isPlaying = false;
        notifyListeners();
      }
    }
  }

  Future<void> playTrack(int index) async {
    if (index < 0 || index >= playlist.length) return;

    final track = playlist[index];

    if (track.previewUrl == null || track.previewUrl!.isEmpty) {
      developer.log('No preview URL for track: ${track.title}');
      return;
    }

    try {
      isLoading = true;
      currentIndex = index;
      currentTrack = track;
      notifyListeners();

      await _player.setUrl(track.previewUrl!);
      await _player.play();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log('Error playing track: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause(int index) async {
    // If tapping the currently loaded track
    if (currentIndex == index) {
      if (isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    // Tapping a different track
    await playTrack(index);
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    currentTrack = null;
    currentIndex = null;
    isPlaying = false;
    notifyListeners();
  }

  Future<void> playNext() async {
    if (currentIndex == null || playlist.isEmpty) return;
    final next = currentIndex! + 1;
    if (next < playlist.length) await playTrack(next);
  }

  Future<void> playPrevious() async {
    if (currentIndex == null || playlist.isEmpty) return;
    final prev = currentIndex! - 1;
    if (prev >= 0) await playTrack(prev);
  }

  void setPlaylist(List<MusicTrack> tracks) {
    playlist = tracks;
    notifyListeners();
  }

  /// Duration stream for progress bar
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
}
