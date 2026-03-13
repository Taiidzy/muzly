import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';
import '../utils/logger.dart';

/// Audio Session Manager
///
/// Manages the Media Session for lock-screen controls and background playback.
/// This is the critical component that enables:
/// - Lock-screen media controls
/// - System media notifications
/// - Bluetooth headphone controls
/// - Smart watch controls
///
/// Uses Media Session API through audio_service package.
class AudioSessionManager extends BaseAudioHandler {
  final AudioPlayer _player;
  
  // Current playback state
  Track? _currentTrack;
  List<Track> _queue = [];
  int _currentIndex = -1;
  
  // Playback settings
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  
  // Subscriptions
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<SequenceState?>? _sequenceSubscription;

  AudioSessionManager() : _player = AudioPlayer() {
    Logger.i('AudioSessionManager initialized', tag: 'AudioSession');
    _initializePlayer();
  }

  /// Initialize player and setup listeners
  void _initializePlayer() {
    // Listen to player state changes
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _updatePlaybackState(state);
      
      // Handle track completion
      if (state.processingState == ProcessingState.completed) {
        _handleTrackComplete();
      }
    });

    // Listen to position changes for progress updates
    _positionSubscription = _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Listen to sequence changes for queue management
    _sequenceSubscription = _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null) {
        _currentIndex = sequenceState.currentIndex;
      }
    });
  }

  /// Update playback state for system media session
  void _updatePlaybackState(PlayerState state) {
    final playing = state.playing;
    final processingState = state.processingState;
    
    // Build media controls based on state
    final controls = [
      MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
    ];

    // Update system playback state
    playbackState.add(playbackState.value.copyWith(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[processingState] ?? AudioProcessingState.idle,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex >= 0 ? _currentIndex : null,
    ));

    Logger.v('Playback state updated: playing=$playing, state=$processingState', tag: 'AudioSession');
  }

  /// Handle track completion based on loop mode
  void _handleTrackComplete() {
    switch (_loopMode) {
      case LoopMode.one:
        // Repeat current track
        _player.seek(Duration.zero);
        _player.play();
        break;
      case LoopMode.all:
        // Will automatically play next track in queue
        break;
      case LoopMode.off:
        // Will stop after current track
        break;
    }
  }

  // ==================== PUBLIC API ====================

  /// Get current track
  Track? get currentTrack => _currentTrack;

  /// Get current queue
  List<Track> get currentQueue => List.unmodifiable(_queue);

  /// Get current track index
  int get currentIndex => _currentIndex;

  /// Get shuffle mode
  bool get isShuffle => _isShuffle;

  /// Get loop mode
  LoopMode get loopMode => _loopMode;

  /// Get audio player instance
  AudioPlayer get player => _player;

  /// Play a track with optional queue
  Future<void> playTrack(Track track, {List<Track>? playlist, int startIndex = 0}) async {
    Logger.i('Playing track: ${track.title} by ${track.artist}', tag: 'AudioSession');

    _currentTrack = track;
    
    if (playlist != null && playlist.isNotEmpty) {
      _queue = List.from(playlist);
      _currentIndex = startIndex.clamp(0, playlist.length - 1);
      
      // Create media items for all tracks in queue
      final mediaItems = _queue.map(_createMediaItem).toList();
      await updateQueue(mediaItems);
      
      // Create concatenated audio source
      final audioSources = <AudioSource>[];
      for (final t in _queue) {
        audioSources.add(AudioSource.uri(Uri.parse(t.audioUrl), tag: t.id));
      }
      
      final playlistSource = ConcatenatingAudioSource(children: audioSources);
      await _player.setAudioSource(playlistSource, initialIndex: _currentIndex);
    } else {
      // Single track
      _queue = [track];
      _currentIndex = 0;
      
      final mediaItem = _createMediaItem(track);
      await updateQueue([mediaItem]);
      await _player.setUrl(track.audioUrl);
    }

    // Update media item and start playback
    await _updateCurrentMediaItem();
    await _player.play();
    
    Logger.d('Track started playing', tag: 'AudioSession');
  }

  /// Play or pause current track
  Future<void> playPause() async {
    Logger.d('Play/Pause toggle', tag: 'AudioSession');
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Play current track
  @override
  Future<void> play() async {
    Logger.d('Play', tag: 'AudioSession');
    await _player.play();
  }

  /// Pause current track
  @override
  Future<void> pause() async {
    Logger.d('Pause', tag: 'AudioSession');
    await _player.pause();
  }

  /// Stop playback
  @override
  Future<void> stop() async {
    Logger.i('Stop', tag: 'AudioSession');
    await _player.stop();
    await super.stop();
  }

  /// Seek to position
  @override
  Future<void> seek(Duration position) async {
    Logger.d('Seek to ${position.inSeconds}s', tag: 'AudioSession');
    await _player.seek(position);
  }

  /// Skip to next track
  @override
  Future<void> skipToNext() async {
    Logger.d('Skip to next', tag: 'AudioSession');
    
    if (_queue.isEmpty) {
      Logger.w('Cannot skip next - queue empty', tag: 'AudioSession');
      return;
    }

    if (_isShuffle) {
      // Random next track in shuffle mode
      final random = DateTime.now().millisecondsSinceEpoch;
      var nextIndex = random % _queue.length;
      if (_queue.length > 1) {
        while (nextIndex == _currentIndex) {
          nextIndex = (nextIndex + 1) % _queue.length;
        }
      }
      Logger.d('Shuffle next: $_currentIndex -> $nextIndex', tag: 'AudioSession');
      await _player.seek(Duration.zero, index: nextIndex);
      _currentIndex = nextIndex;
      _currentTrack = _queue[_currentIndex];
      await _updateCurrentMediaItem();
    } else {
      // Use just_audio's built-in skip
      if (_currentIndex < _queue.length - 1) {
        await _player.seekToNext();
        _currentIndex++;
        _currentTrack = _queue[_currentIndex];
        await _updateCurrentMediaItem();
      } else {
        Logger.w('Already at last track', tag: 'AudioSession');
      }
    }
  }

  /// Skip to previous track
  @override
  Future<void> skipToPrevious() async {
    Logger.d('Skip to previous', tag: 'AudioSession');
    
    if (_queue.isEmpty) {
      Logger.w('Cannot skip previous - queue empty', tag: 'AudioSession');
      return;
    }

    // If more than 3 seconds into the track, restart it
    if (_player.position.inSeconds > 3) {
      Logger.d('Restarting current track (>3s)', tag: 'AudioSession');
      await _player.seek(Duration.zero);
      return;
    }

    if (_isShuffle) {
      // Random previous track in shuffle mode
      final random = DateTime.now().millisecondsSinceEpoch;
      var prevIndex = random % _queue.length;
      if (_queue.length > 1) {
        while (prevIndex == _currentIndex) {
          prevIndex = (prevIndex + 1) % _queue.length;
        }
      }
      Logger.d('Shuffle previous: $_currentIndex -> $prevIndex', tag: 'AudioSession');
      await _player.seek(Duration.zero, index: prevIndex);
      _currentIndex = prevIndex;
      _currentTrack = _queue[_currentIndex];
      await _updateCurrentMediaItem();
    } else {
      // Use just_audio's built-in skip
      if (_currentIndex > 0) {
        await _player.seekToPrevious();
        _currentIndex--;
        _currentTrack = _queue[_currentIndex];
        await _updateCurrentMediaItem();
      } else {
        Logger.w('Already at first track', tag: 'AudioSession');
      }
    }
  }

  /// Toggle shuffle mode
  Future<void> setShuffle(bool enabled) async {
    _isShuffle = enabled;
    await _player.setShuffleModeEnabled(enabled);
    Logger.d('Shuffle ${enabled ? "enabled" : "disabled"}', tag: 'AudioSession');
  }

  /// Set loop mode
  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    await _player.setLoopMode(mode);
    Logger.d('Loop mode set to $mode', tag: 'AudioSession');
  }

  /// Add track to queue
  Future<void> addToQueue(Track track, {int? position}) async {
    if (position != null && position >= 0 && position <= _queue.length) {
      _queue.insert(position, track);
      Logger.d('Track inserted at position $position', tag: 'AudioSession');
    } else {
      _queue.add(track);
      Logger.d('Track added to end of queue', tag: 'AudioSession');
    }
  }

  /// Remove track from queue
  Future<void> removeFromQueue(String trackId) async {
    final index = _queue.indexWhere((t) => t.id == trackId);
    if (index >= 0) {
      // Don't remove currently playing track
      if (index != _currentIndex) {
        _queue.removeAt(index);
        if (index < _currentIndex) {
          _currentIndex--;
        }
        Logger.d('Track removed from queue at index $index', tag: 'AudioSession');
      } else {
        Logger.w('Cannot remove currently playing track', tag: 'AudioSession');
      }
    }
  }

  /// Clear queue (except current track)
  Future<void> clearQueue() async {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      final currentTrack = _queue[_currentIndex];
      _queue = [currentTrack];
      _currentIndex = 0;
      Logger.d('Queue cleared, keeping current track', tag: 'AudioSession');
    } else {
      _queue = [];
      _currentIndex = -1;
      Logger.d('Queue cleared', tag: 'AudioSession');
    }
  }

  /// Move track in queue (for drag & drop)
  Future<void> moveTrackInQueue(int fromIndex, int toIndex) async {
    if (fromIndex >= 0 && fromIndex < _queue.length &&
        toIndex >= 0 && toIndex < _queue.length) {
      final track = _queue.removeAt(fromIndex);
      _queue.insert(toIndex, track);
      
      // Update current index if needed
      if (fromIndex == _currentIndex) {
        _currentIndex = toIndex;
      } else if (fromIndex < _currentIndex && toIndex >= _currentIndex) {
        _currentIndex--;
      } else if (fromIndex > _currentIndex && toIndex <= _currentIndex) {
        _currentIndex++;
      }
      
      Logger.d('Track moved from $fromIndex to $toIndex', tag: 'AudioSession');
    }
  }

  /// Update current media item in system session
  Future<void> _updateCurrentMediaItem() async {
    if (_currentTrack != null) {
      final mediaItem = _createMediaItem(_currentTrack!);
      await updateMediaItem(mediaItem);
    }
  }

  /// Create MediaItem from Track for system media session
  MediaItem _createMediaItem(Track track) {
    final artUri = track.albumArtUrl != null && track.albumArtUrl!.isNotEmpty
        ? Uri.parse(track.albumArtUrl!)
        : null;

    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album ?? 'Unknown Album',
      duration: Duration(milliseconds: track.durationMs),
      artUri: artUri,
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    Logger.i('AudioSessionManager disposing', tag: 'AudioSession');
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _sequenceSubscription?.cancel();
    await _player.dispose();
  }
}
