import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/models.dart';
import 'api_service.dart';
import '../utils/logger.dart';

/// Audio Player Service
/// 
/// Handles audio playback using just_audio
/// Provides streams for position, duration, and playback state
/// Supports playlist management and track seeking
class AudioPlayerService {
  final AudioPlayer _player;
  final ApiService _apiService;
  
  // Current playlist
  List<Track> _playlist = [];
  int _currentIndex = -1;
  
  // Playback settings
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  
  // Like state for tracks
  final Map<String, bool> _likedTracks = {};

  AudioPlayerService({required ApiService apiService})
      : _player = AudioPlayer(),
        _apiService = apiService {
    Logger.i('AudioPlayerService initialized', tag: 'Audio');
    
    // Handle player state changes for queue management
    _player.playerStateStream.listen((state) {
      Logger.playerState(
        '${state.playing ? "Playing" : "Paused"} - ${state.processingState}',
        trackTitle: currentTrack?.title,
        position: _player.position,
        duration: _player.duration ?? Duration.zero,
      );
      
      if (state.processingState == ProcessingState.completed) {
        Logger.d('Track completed', tag: 'Audio');
        _handleTrackComplete();
      }
    });
  }

  /// Current playing track
  Track? get currentTrack => 
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  /// Current playlist
  List<Track> get playlist => List.unmodifiable(_playlist);

  /// Current track index
  int get currentIndex => _currentIndex;

  /// Whether shuffle is enabled
  bool get isShuffle => _isShuffle;

  /// Current loop mode
  LoopMode get loopMode => _loopMode;

  /// Check if a track is liked
  bool isLiked(String trackId) => _likedTracks[trackId] ?? false;

  /// Stream of player state (playing, paused, loading, etc.)
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream of current position
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of buffered position
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  /// Stream of total duration
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream of playing state (playing or not)
  Stream<bool> get playingStream => 
      playerStateStream.map((state) => state.playing);

  /// Stream of loading state
  Stream<bool> get loadingStream =>
      playerStateStream.map((state) => 
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering);

  /// Combined stream for UI state
  Stream<PlayerStateInfo> get playerStateInfoStream => 
      Rx.combineLatest4<PlayerState, Duration, Duration?, bool, PlayerStateInfo>(
        playerStateStream,
        positionStream,
        durationStream,
        playingStream,
        (playerState, position, duration, isPlaying) => PlayerStateInfo(
          playerState: playerState,
          position: position,
          duration: duration ?? Duration.zero,
          isPlaying: isPlaying,
          isLoading: playerState.processingState == ProcessingState.loading ||
                     playerState.processingState == ProcessingState.buffering,
        ),
      );

  /// Play a list of tracks starting from a specific index
  Future<void> playPlaylist(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) {
      Logger.w('Attempted to play empty playlist', tag: 'Audio');
      return;
    }
    
    _playlist = List.from(tracks);
    _currentIndex = startIndex;
    
    final track = _playlist[_currentIndex];
    final url = _apiService.getStreamUrl(track.id);
    
    Logger.i('Playing playlist: ${track.title} by ${track.artistName}', tag: 'Audio');
    Logger.d('Audio URL: $url', tag: 'Audio');
    
    await _player.setUrl(url);
    await _player.play();
  }

  /// Play a single track
  Future<void> playTrack(Track track, {List<Track>? playlist}) async {
    Logger.i('Playing track: ${track.title} by ${track.artistName}', tag: 'Audio');
    
    if (playlist != null && playlist.isNotEmpty) {
      _playlist = List.from(playlist);
      _currentIndex = playlist.indexWhere((t) => t.id == track.id);
      if (_currentIndex < 0) _currentIndex = 0;
    } else {
      _playlist = [track];
      _currentIndex = 0;
    }
    
    final url = _apiService.getStreamUrl(track.id);
    Logger.d('Audio URL: $url', tag: 'Audio');
    
    await _player.setUrl(url);
    await _player.play();
  }

  /// Play or pause current track
  Future<void> playPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Play current track
  Future<void> play() async {
    await _player.play();
  }

  /// Pause current track
  Future<void> pause() async {
    await _player.pause();
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Skip to next track
  Future<void> skipNext() async {
    if (_playlist.isEmpty) {
      Logger.w('Cannot skip next - playlist is empty', tag: 'Audio');
      return;
    }
    
    final previousIndex = _currentIndex;
    
    if (_isShuffle) {
      // Random next track in shuffle mode
      final random = DateTime.now().millisecondsSinceEpoch;
      var nextIndex = random % _playlist.length;
      if (_playlist.length > 1) {
        while (nextIndex == _currentIndex) {
          nextIndex = (nextIndex + 1) % _playlist.length;
        }
      }
      _currentIndex = nextIndex;
      Logger.d('Shuffle: track $previousIndex -> $nextIndex', tag: 'Audio');
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      Logger.d('Next track: $previousIndex -> $_currentIndex', tag: 'Audio');
    }
    
    final track = _playlist[_currentIndex];
    final url = _apiService.getStreamUrl(track.id);
    await _player.setUrl(url);
    await _player.play();
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    if (_playlist.isEmpty) {
      Logger.w('Cannot skip previous - playlist is empty', tag: 'Audio');
      return;
    }
    
    // If more than 3 seconds into the track, restart it
    if (_player.position.inSeconds > 3) {
      Logger.d('Restarting current track (position > 3s)', tag: 'Audio');
      await _player.seek(Duration.zero);
      return;
    }
    
    final previousIndex = _currentIndex;
    
    if (_isShuffle) {
      final random = DateTime.now().millisecondsSinceEpoch;
      var prevIndex = random % _playlist.length;
      if (_playlist.length > 1) {
        while (prevIndex == _currentIndex) {
          prevIndex = (prevIndex + 1) % _playlist.length;
        }
      }
      _currentIndex = prevIndex;
      Logger.d('Shuffle previous: track $previousIndex -> $prevIndex', tag: 'Audio');
    } else {
      _currentIndex = (_currentIndex - 1) % _playlist.length;
      if (_currentIndex < 0) _currentIndex = _playlist.length - 1;
      Logger.d('Previous track: $previousIndex -> $_currentIndex', tag: 'Audio');
    }
    
    final track = _playlist[_currentIndex];
    final url = _apiService.getStreamUrl(track.id);
    await _player.setUrl(url);
    await _player.play();
  }

  /// Toggle shuffle mode
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
  }

  /// Cycle through loop modes: off -> one -> all
  void cycleLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.off;
        break;
    }
    _player.setLoopMode(_loopMode);
  }

  /// Toggle like status for current track
  void toggleLike(String trackId) {
    _likedTracks[trackId] = !(_likedTracks[trackId] ?? false);
  }

  /// Handle track completion
  void _handleTrackComplete() {
    if (_loopMode == LoopMode.one) {
      // Repeat current track
      _player.seek(Duration.zero);
      _player.play();
    } else if (_loopMode == LoopMode.all || _currentIndex < _playlist.length - 1) {
      // Play next track
      skipNext();
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  /// Set playback speed (0.5 to 2.0)
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Dispose the player
  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Player state info for UI
class PlayerStateInfo {
  final PlayerState playerState;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;

  PlayerStateInfo({
    required this.playerState,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.isLoading,
  });

  /// Get playback progress (0.0 to 1.0)
  double get progress => 
      duration.inMilliseconds > 0 
          ? position.inMilliseconds / duration.inMilliseconds 
          : 0.0;
}
