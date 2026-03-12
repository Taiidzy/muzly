import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';
import '../utils/logger.dart';

/// Audio Handler for Background Playback
///
/// Handles media notifications and background audio controls
/// Integrates with just_audio for playback
class MuzlyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Current track
  Track? _currentTrack;
  List<Track> _queue = [];

  MuzlyAudioHandler() : _player = AudioPlayer() {
    Logger.i('MuzlyAudioHandler initialized', tag: 'AudioHandler');
    
    // Listen to player state changes
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _queue.indexWhere((t) => t.id == _currentTrack?.id),
      ));
      
      Logger.v('Player state updated: playing=$playing, processingState=$processingState', tag: 'AudioHandler');
    });

    // Listen to position updates
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Handle track completion
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        Logger.d('Track completed, skipping to next', tag: 'AudioHandler');
        skipToNext();
      }
    });
  }

  /// Play a track
  Future<void> playTrack(Track track, {List<Track>? playlist}) async {
    Logger.i('Playing track via AudioHandler: ${track.title}', tag: 'AudioHandler');
    
    _currentTrack = track;
    if (playlist != null) {
      _queue = playlist;
      Logger.d('Playlist set with ${playlist.length} tracks', tag: 'AudioHandler');
    }

    final mediaItem = _createMediaItem(track);
    await _player.setUrl(track.audioUrl);
    await _player.play();
    
    // Update media item
    await updateMediaItem(mediaItem);
    Logger.d('Media item updated', tag: 'AudioHandler');
  }

  /// Play or pause
  Future<void> playPause() async {
    Logger.d('Play/Pause toggle requested', tag: 'AudioHandler');
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Play
  @override
  Future<void> play() {
    Logger.d('Play', tag: 'AudioHandler');
    return _player.play();
  }

  /// Pause
  @override
  Future<void> pause() {
    Logger.d('Pause', tag: 'AudioHandler');
    return _player.pause();
  }

  /// Stop
  @override
  Future<void> stop() async {
    Logger.i('Stop', tag: 'AudioHandler');
    await _player.stop();
    await super.stop();
  }

  /// Seek to position
  @override
  Future<void> seek(Duration position) {
    Logger.d('Seek to ${position.inSeconds}s', tag: 'AudioHandler');
    return _player.seek(position);
  }

  /// Skip to next track
  @override
  Future<void> skipToNext() async {
    Logger.d('Skip to next requested', tag: 'AudioHandler');
    
    if (_queue.isEmpty || _currentTrack == null) {
      Logger.w('Cannot skip next - queue empty or no current track', tag: 'AudioHandler');
      return;
    }

    final currentIndex = _queue.indexWhere((t) => t.id == _currentTrack?.id);
    if (currentIndex < 0 || currentIndex >= _queue.length - 1) {
      Logger.w('Cannot skip next - already at last track', tag: 'AudioHandler');
      return;
    }

    final nextTrack = _queue[currentIndex + 1];
    Logger.i('Skipping to next track: ${nextTrack.title}', tag: 'AudioHandler');
    await playTrack(nextTrack);
  }

  /// Skip to previous track
  @override
  Future<void> skipToPrevious() async {
    Logger.d('Skip to previous requested', tag: 'AudioHandler');
    
    if (_queue.isEmpty || _currentTrack == null) {
      Logger.w('Cannot skip previous - queue empty or no current track', tag: 'AudioHandler');
      return;
    }

    final currentIndex = _queue.indexWhere((t) => t.id == _currentTrack?.id);
    if (currentIndex <= 0) {
      Logger.w('Cannot skip previous - already at first track', tag: 'AudioHandler');
      return;
    }

    final previousTrack = _queue[currentIndex - 1];
    Logger.i('Skipping to previous track: ${previousTrack.title}', tag: 'AudioHandler');
    await playTrack(previousTrack);
  }

  /// Set shuffle mode
  Future<void> setShuffle(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
  }

  /// Set loop mode
  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  /// Create MediaItem from Track
  MediaItem _createMediaItem(Track track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artistName,
      album: track.albumName,
      duration: Duration(milliseconds: track.durationMs),
      artUri: track.albumArtUrl != null && track.albumArtUrl!.isNotEmpty
          ? Uri.parse(track.albumArtUrl!)
          : null,
    );
  }

  /// Update current media item
  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    await updateQueue([mediaItem]);
  }

  /// Dispose resources
  Future<void> disposeResources() async {
    await _playerStateSubscription?.cancel();
    await _player.dispose();
  }
}
