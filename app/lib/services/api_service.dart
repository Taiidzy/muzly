import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/models.dart';
import '../utils/logger.dart';
import 'api_config.dart';

/// API Service for communicating with the backend
///
/// Backend: FastAPI (Python) with PostgreSQL
/// Base URL: https://muzly.macrofox.org
class ApiService {
  final Dio _dio;
  String _baseUrl;

  // Backend base URL
  static String get baseUrl => ApiConfig.baseUrl;

  // Store auth token for authenticated requests
  String? _authToken;

  ApiService({String? baseUrl})
    : _baseUrl = baseUrl ?? ApiConfig.baseUrl,
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    Logger.i('API Service initialized with base URL: $_baseUrl', tag: 'API');

    // Configure HTTP client to accept bad certificates (debug only)
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        if (!kReleaseMode) {
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) {
                Logger.w('Accepting bad certificate for $host:$port', tag: 'API');
                return true; // Accept the certificate
              };
        }
        return client;
      },
    );

    // Add request interceptor for auth and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          Logger.apiRequest(options.method, options.path, body: options.data);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          Logger.apiResponse(
            response.requestOptions.path,
            response.statusCode ?? 0,
            data: response.data,
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          Logger.e('API Error: ${error.message}', tag: 'API', error: error);
          return handler.next(error);
        },
      ),
    );
  }

  /// Set authentication token
  void setAuthToken(String? token) {
    _authToken = token;
    Logger.d('Auth token ${token != null ? "set" : "cleared"}', tag: 'API');
  }

  /// Update base URL at runtime (e.g., when user changes server)
  void updateBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
    Logger.i('API base URL updated: $_baseUrl', tag: 'API');
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== TRACKS ====================

  /// Get all tracks with optional search
  /// Backend: GET /tracks
  Future<List<Track>> getTracks({String? query, int limit = 200}) async {
    try {
      final response = await _dio.get(
        '/api/tracks',
        queryParameters: {
          'page': 1,
          'page_size': limit,
          if (query != null && query.trim().isNotEmpty) 'search': query,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List?) ?? [];
        final tracks = items
            .map((t) => _mapTrackJson(t as Map<String, dynamic>))
            .map((t) => Track.fromJson(t))
            .toList();
        return tracks;
      }
      throw ApiException('Failed to fetch tracks: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get a single track by ID
  /// Backend: GET /tracks/{track_id}
  Future<Track> getTrack(String id) async {
    try {
      final response = await _dio.get('/api/tracks/$id');

      if (response.statusCode == 200) {
        final data = _mapTrackJson(response.data as Map<String, dynamic>);
        return Track.fromJson(data);
      }
      throw ApiException('Failed to fetch track: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get audio stream URL for a track
  /// Backend: GET /tracks/{track_id}/stream
  String getStreamUrl(String trackId) {
    return '$_baseUrl/api/tracks/$trackId/stream';
  }

  /// Get download URL for a track
  /// Backend: GET /tracks/{track_id}/download
  String getDownloadUrl(String trackId) {
    return '$_baseUrl/api/tracks/$trackId/download';
  }

  // ==================== ALBUMS ====================

  /// Backend doesn't have a dedicated albums endpoint
  /// We'll return empty list or derive from tracks
  Future<List<Album>> getAlbums({int page = 1, int limit = 50}) async {
    Logger.d(
      'getAlbums: backend does not support albums, returning empty list',
      tag: 'API',
    );
    return [];
  }

  /// Get album by ID - not supported by backend
  Future<Album> getAlbum(String id) async {
    throw ApiException('Albums are not supported by the backend');
  }

  /// Get tracks for an album - not supported by backend
  Future<List<Track>> getAlbumTracks(String albumId) async {
    throw ApiException('Albums are not supported by the backend');
  }

  // ==================== PLAYLISTS ====================

  /// Get user's playlists
  /// Backend: GET /playlists
  Future<List<Playlist>> getPlaylists({int page = 1, int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/api/playlists',
        queryParameters: {
          'page': page,
          'page_size': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List?) ?? [];
        return items
            .map((p) => _mapPlaylistJson(p as Map<String, dynamic>))
            .map((p) => Playlist.fromJson(p))
            .toList();
      }
      throw ApiException('Failed to fetch playlists: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get playlist by ID with tracks
  /// Backend: GET /playlists/{id}/tracks
  Future<Playlist> getPlaylist(String id) async {
    try {
      final response = await _dio.get('/api/playlists/$id');
      if (response.statusCode == 200) {
        final data = _mapPlaylistJson(response.data as Map<String, dynamic>);
        return Playlist.fromJson(data);
      }
      throw ApiException('Failed to fetch playlist: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch playlist: $e');
    }
  }

  /// Get tracks for a playlist
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    try {
      final response = await _dio.get('/api/playlists/$playlistId');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final playlist = Playlist.fromJson(_mapPlaylistJson(data));
        return playlist.tracks ?? [];
      }
      return [];
    } catch (e) {
      throw ApiException('Failed to fetch playlist tracks: $e');
    }
  }

  /// Get random/featured playlists
  /// Backend doesn't have random playlists; we'll sample locally
  Future<List<Playlist>> getRandomPlaylists() async {
    try {
      final playlists = await getPlaylists();
      if (playlists.isEmpty) return [];
      playlists.shuffle();
      return playlists.take(6).toList();
    } on DioException catch (e) {
      Logger.w('Failed to fetch random playlists: ${e.message}', tag: 'API');
      return [];
    }
  }

  /// Get user's favorites playlist
  /// Backend: playlist with is_favorites=true
  Future<List<Track>> getFavorites() async {
    try {
      final response = await _dio.get('/api/me/favorites');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List?) ?? [];
        return items
            .map((item) => item['track'] as Map<String, dynamic>)
            .map((track) => _mapTrackJson(track))
            .map((track) => Track.fromJson(track))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      Logger.w('Failed to fetch favorites: ${e.message}', tag: 'API');
      return [];
    }
  }

  /// Toggle track in favorites
  /// Backend: add/remove track from favorites playlist
  Future<bool> toggleFavorite(String trackId) async {
    final parsedId = int.tryParse(trackId);
    if (parsedId == null) {
      throw ApiException('Invalid track id: $trackId');
    }
    try {
      await _dio.post('/api/me/favorites/$parsedId');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        await _dio.delete('/api/me/favorites/$parsedId');
        return false;
      }
      throw _handleDioError(e);
    }
  }

  // ==================== ARTISTS ====================

  /// Backend doesn't have a dedicated artists endpoint
  Future<List<Artist>> getArtists({int page = 1, int limit = 50}) async {
    Logger.d(
      'getArtists: backend does not support artists, returning empty list',
      tag: 'API',
    );
    return [];
  }

  /// Get artist by ID - not supported by backend
  Future<Artist> getArtist(String id) async {
    throw ApiException('Artists are not supported by the backend');
  }

  // ==================== SEARCH ====================

  /// Search for tracks
  /// Backend: GET /tracks?q={query}
  Future<SearchResults> search(String query, {String? type}) async {
    try {
      Logger.d('Search query: "$query" (type: ${type ?? "all"})', tag: 'API');

      // Search tracks
      final tracks = await getTracks(query: query);

      // Search playlists (if user is authenticated)
      List<Playlist> playlists = [];
      if (_authToken != null) {
        try {
          final userPlaylists = await getPlaylists();
          if (query.isNotEmpty) {
            playlists = userPlaylists
                .where(
                  (p) => p.title.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
          } else {
            playlists = userPlaylists;
          }
        } catch (e) {
          Logger.w('Failed to search playlists: $e', tag: 'API');
        }
      }

      return SearchResults(
        tracks: tracks,
        albums: [], // Backend doesn't support albums
        artists: [], // Backend doesn't support artists
        playlists: playlists,
      );
    } catch (e) {
      throw ApiException('Search failed: $e');
    }
  }

  // ==================== HISTORY ====================

  /// Get recent listening history
  /// Backend doesn't provide history yet
  Future<List<Track>> getRecentHistory() async {
    return [];
  }

  /// Add track to listening history
  /// Backend doesn't provide history yet
  Future<void> addToHistory(String trackId) async {
    return;
  }

  // ==================== AUTH (Optional) ====================

  /// Login
  /// Backend: POST /auth/login (username + password)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'username': email, 'password': password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String;
        setAuthToken(token);
        return {
          'token': token,
          'user': {'username': email},
        };
      }
      throw ApiException('Login failed: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Register
  /// Backend: POST /auth/register
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    throw ApiException('Registration is not supported by the backend');
  }

  /// Get current user
  /// Backend: GET /auth/me
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return null;
  }

  /// Logout (clear token)
  void logout() {
    setAuthToken(null);
    Logger.i('User logged out', tag: 'API');
  }

  // ==================== ERROR HANDLING ====================

  /// Handle Dio errors and return appropriate API exceptions
  ApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timeout. Please try again.');
      case DioExceptionType.connectionError:
        return ApiException(
          'Cannot connect to server. Please check your connection.',
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        String message = 'Server error: $status';
        if (data is Map<String, dynamic> && data.containsKey('error')) {
          message = data['error'];
        }
        return ApiException(message);
      case DioExceptionType.cancel:
        return ApiException('Request cancelled');
      default:
        return ApiException('An unexpected error occurred: ${e.message}');
    }
  }
}

Map<String, dynamic> _mapTrackJson(Map<String, dynamic> json) {
  final id = json['id']?.toString() ?? '';
  final coverPath =
      json['cover_path'] ??
      json['track_cover_path'] ??
      json['album_cover_path'] ??
      json['artist_avatar_path'];
  final coverUrl = coverPath != null ? '/media/$coverPath' : null;
  return {
    ...json,
    'streamUrl': json['streamUrl'] ?? '/api/tracks/$id/stream',
    'cover200Url': json['cover200Url'] ?? coverUrl,
    'cover800Url': json['cover800Url'] ?? coverUrl,
  };
}

Map<String, dynamic> _mapPlaylistJson(Map<String, dynamic> json) {
  final isFavorites = json['is_favorites'] == true;
  final tracks = json['tracks'];
  final mappedTracks =
      tracks is List
          ? tracks
              .map((t) {
                final trackItem = t as Map<String, dynamic>;
                final track = trackItem['track'] is Map<String, dynamic>
                    ? trackItem['track'] as Map<String, dynamic>
                    : trackItem;
                return _mapTrackJson(track);
              })
              .toList()
          : null;
  return {
    ...json,
    if (mappedTracks != null) 'tracks': mappedTracks,
    'title': json['title'] ?? json['name'],
    'kind': json['kind'] ?? (isFavorites ? 'favorites' : 'custom'),
    'isPublic': json['isPublic'] ?? true,
    'trackCount': json['trackCount'] ?? (mappedTracks?.length ?? 0),
  };
}

/// Search results container
class SearchResults {
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;

  SearchResults({
    required this.tracks,
    required this.albums,
    required this.artists,
    this.playlists = const [],
  });
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
