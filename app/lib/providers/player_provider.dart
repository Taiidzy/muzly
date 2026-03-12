import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/logger.dart';

/// Global Player Provider using Provider pattern
/// 
/// Manages the global state of the music player
/// Accessible from anywhere in the app
class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService _audioService;
  final ApiService _apiService;

  // State
  Track? _currentTrack;
  List<Track> _queue = [];
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;

  // Library state
  List<Track> _tracks = [];
  List<Track> _recentTracks = [];
  List<Playlist> _featuredPlaylists = [];
  final List<Album> _albums = [];
  final List<Playlist> _playlists = [];
  final List<Artist> _artists = [];
  bool _isLoadingLibrary = false;
  String? _libraryError;

  // Search state
  bool _isSearching = false;
  SearchResults? _searchResults;
  String? _searchError;

  PlayerProvider({
    required AudioPlayerService audioService,
    required ApiService apiService,
  })  : _audioService = audioService,
        _apiService = apiService {
    Logger.i('PlayerProvider initialized', tag: 'Provider');
    _initPlayerListeners();
  }

  // Getters
  Track? get currentTrack => _currentTrack;
  List<Track> get queue => List.unmodifiable(_queue);
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get error => _error;
  bool get hasError => _error != null;

  // Library getters
  List<Track> get tracks => List.unmodifiable(_tracks);
  List<Track> get recentTracks => List.unmodifiable(_recentTracks);
  List<Playlist> get featuredPlaylists => List.unmodifiable(_featuredPlaylists);
  List<Album> get albums => List.unmodifiable(_albums);
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Artist> get artists => List.unmodifiable(_artists);
  bool get isLoadingLibrary => _isLoadingLibrary;
  String? get libraryError => _libraryError;

  // Search getters
  bool get isSearching => _isSearching;
  SearchResults? get searchResults => _searchResults;
  String? get searchError => _searchError;

  /// Get formatted position string (e.g., "1:23")
  String get formattedPosition => _formatDuration(_position);

  /// Get formatted duration string (e.g., "3:45")
  String get formattedDuration => _formatDuration(_duration);

  /// Get playback progress (0.0 to 1.0)
  double get progress =>
      _duration.inMilliseconds > 0
          ? _position.inMilliseconds / _duration.inMilliseconds
          : 0.0;

  /// Check if a track is liked
  bool isLiked(String trackId) => _audioService.isLiked(trackId);

  /// Initialize player listeners
  void _initPlayerListeners() {
    _audioService.playerStateInfoStream.listen((info) {
      _position = info.position;
      _duration = info.duration;
      _isPlaying = info.isPlaying;
      _isLoading = info.isLoading;
      _currentTrack = _audioService.currentTrack;
      _queue = _audioService.playlist;
      _isShuffle = _audioService.isShuffle;
      _loopMode = _audioService.loopMode;
      notifyListeners();
    });
  }

  /// Load library data
  Future<void> loadLibrary() async {
    Logger.i('Loading library...', tag: 'Provider');
    _isLoadingLibrary = true;
    _libraryError = null;
    notifyListeners();

    try {
      // Load tracks and recent history
      final tracksFuture = _apiService.getTracks();
      final recentFuture = _apiService.getRecentHistory();
      final randomPlaylistsFuture = _apiService.getRandomPlaylists();
      
      final results = await Future.wait([
        tracksFuture,
        recentFuture,
        randomPlaylistsFuture,
      ]);

      _tracks = results[0] as List<Track>;
      _recentTracks = results[1] as List<Track>;
      _featuredPlaylists = results[2] as List<Playlist>;
      
      Logger.i('Library loaded: ${_tracks.length} tracks, ${_recentTracks.length} recent, ${_featuredPlaylists.length} featured playlists', tag: 'Provider');
    } catch (e, stackTrace) {
      _libraryError = e.toString();
      Logger.e('Failed to load library', tag: 'Provider', error: e, stackTrace: stackTrace);
    } finally {
      _isLoadingLibrary = false;
      notifyListeners();
    }
  }

  /// Play a track with optional playlist
  Future<void> playTrack(Track track, {List<Track>? playlist}) async {
    Logger.i('Play track requested: ${track.title}', tag: 'Provider');
    _error = null;
    notifyListeners();

    try {
      await _audioService.playTrack(track, playlist: playlist);
      Logger.i('Track playing successfully', tag: 'Provider');
    } catch (e, stackTrace) {
      _error = e.toString();
      Logger.e('Failed to play track', tag: 'Provider', error: e, stackTrace: stackTrace);
    }
  }

  /// Play a playlist from specific index
  Future<void> playPlaylist(List<Track> tracks, {int startIndex = 0}) async {
    _error = null;
    notifyListeners();

    try {
      await _audioService.playPlaylist(tracks, startIndex: startIndex);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle play/pause
  Future<void> playPause() async {
    try {
      await _audioService.playPause();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Skip to next track
  Future<void> skipNext() async {
    try {
      await _audioService.skipNext();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    try {
      await _audioService.skipPrevious();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioService.seek(position);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle shuffle
  void toggleShuffle() {
    _audioService.toggleShuffle();
    _isShuffle = _audioService.isShuffle;
    notifyListeners();
  }

  /// Cycle loop mode
  void cycleLoopMode() {
    _audioService.cycleLoopMode();
    _loopMode = _audioService.loopMode;
    notifyListeners();
  }

  /// Toggle like for current track
  void toggleLike() {
    if (_currentTrack != null) {
      _audioService.toggleLike(_currentTrack!.id);
      notifyListeners();
    }
  }

  /// Search for tracks, albums, and artists
  Future<void> search(String query) async {
    Logger.d('Search query: "$query"', tag: 'Provider');
    
    if (query.isEmpty) {
      _searchResults = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      _searchResults = await _apiService.search(query);
      Logger.i('Search completed: ${_searchResults?.tracks.length ?? 0} tracks, ${_searchResults?.albums.length ?? 0} albums, ${_searchResults?.artists.length ?? 0} artists', tag: 'Provider');
    } catch (e, stackTrace) {
      _searchError = e.toString();
      Logger.e('Search failed for query: "$query"', tag: 'Provider', error: e, stackTrace: stackTrace);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    Logger.d('Clearing search results', tag: 'Provider');
    _searchResults = null;
    _searchError = null;
    _isSearching = false;
    notifyListeners();
  }

  /// Format duration to mm:ss
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get tracks for an album
  Future<List<Track>> getAlbumTracks(String albumId) async {
    Logger.d('Getting tracks for album: $albumId', tag: 'Provider');
    return await _apiService.getAlbumTracks(albumId);
  }

  /// Get tracks for a playlist
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    Logger.d('Getting tracks for playlist: $playlistId', tag: 'Provider');
    return await _apiService.getPlaylistTracks(playlistId);
  }

  @override
  void dispose() {
    Logger.i('PlayerProvider disposed', tag: 'Provider');
    _audioService.dispose();
    super.dispose();
  }
}
