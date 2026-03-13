import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/logger.dart';

/// Listening History Service
///
/// Tracks user's listening history for:
/// - Recently played tracks
/// - Listening statistics
/// - Quick resume of last played tracks
class ListeningHistoryService {
  static const String _keyHistory = 'listening_history';
  static const int defaultMaxHistory = 100;

  final Future<SharedPreferences> _prefsFuture;
  SharedPreferences? _prefsCache;
  final int _maxHistory;

  ListeningHistoryService(this._prefsFuture, {int maxHistory = defaultMaxHistory})
      : _maxHistory = maxHistory;

  Future<SharedPreferences> get _prefs async {
    _prefsCache ??= await _prefsFuture;
    return _prefsCache!;
  }

  /// Add track to listening history
  Future<void> addToHistory(Track track) async {
    try {
      final prefs = await _prefs;
      // Get existing history
      final history = await getHistory();

      // Remove existing entry for this track (to avoid duplicates)
      history.removeWhere((t) => t.track.id == track.id);

      // Add track at the beginning (most recent first)
      history.insert(0, HistoryEntry(
        track: track,
        playedAt: DateTime.now(),
      ));

      // Limit history size
      if (history.length > _maxHistory) {
        history.removeRange(_maxHistory, history.length);
      }

      // Save history
      final historyJson = jsonEncode(
        history.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_keyHistory, historyJson);

      Logger.d('Added to history: ${track.title}', tag: 'History');
    } catch (e, stackTrace) {
      Logger.e('Failed to add to history', tag: 'History', error: e, stackTrace: stackTrace);
    }
  }

  /// Get listening history
  Future<List<HistoryEntry>> getHistory() async {
    try {
      final prefs = await _prefs;
      final historyJson = prefs.getString(_keyHistory);
      if (historyJson == null) return [];

      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      Logger.e('Failed to get history', tag: 'History', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get recent tracks (just the tracks, not full history entries)
  Future<List<Track>> getRecentTracks({int limit = 20}) async {
    final history = await getHistory();
    return history.take(limit).map((e) => e.track).toList();
  }

  /// Clear listening history
  Future<void> clearHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_keyHistory);
    Logger.i('Listening history cleared', tag: 'History');
  }

  /// Remove specific track from history
  Future<void> removeFromHistory(String trackId) async {
    try {
      final prefs = await _prefs;
      final history = await getHistory();
      history.removeWhere((e) => e.track.id == trackId);

      final historyJson = jsonEncode(
        history.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_keyHistory, historyJson);

      Logger.d('Removed from history: $trackId', tag: 'History');
    } catch (e, stackTrace) {
      Logger.e('Failed to remove from history', tag: 'History', error: e, stackTrace: stackTrace);
    }
  }

  /// Get listening statistics
  Future<ListeningStats> getStats() async {
    final history = await getHistory();
    
    // Count tracks by artist
    final artistCounts = <String, int>{};
    for (final entry in history) {
      final artist = entry.track.artist;
      artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
    }

    // Count tracks by album
    final albumCounts = <String, int>{};
    for (final entry in history) {
      final album = entry.track.album ?? 'Unknown Album';
      albumCounts[album] = (albumCounts[album] ?? 0) + 1;
    }

    // Find most played tracks
    final trackCounts = <String, int>{};
    for (final entry in history) {
      final id = entry.track.id;
      trackCounts[id] = (trackCounts[id] ?? 0) + 1;
    }

    // Get top artists
    final topArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top albums
    final topAlbums = albumCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListeningStats(
      totalPlays: history.length,
      uniqueTracks: trackCounts.length,
      topArtists: topArtists.take(10).map((e) => ArtistPlayCount(
        artist: e.key,
        playCount: e.value,
      )).toList(),
      topAlbums: topAlbums.take(10).map((e) => AlbumPlayCount(
        album: e.key,
        playCount: e.value,
      )).toList(),
    );
  }
}

/// History entry with timestamp
class HistoryEntry {
  final Track track;
  final DateTime playedAt;

  HistoryEntry({
    required this.track,
    required this.playedAt,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      track: Track.fromJson(json['track'] as Map<String, dynamic>),
      playedAt: DateTime.parse(json['played_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'track': track.toJson(),
      'played_at': playedAt.toIso8601String(),
    };
  }
}

/// Listening statistics
class ListeningStats {
  final int totalPlays;
  final int uniqueTracks;
  final List<ArtistPlayCount> topArtists;
  final List<AlbumPlayCount> topAlbums;

  ListeningStats({
    required this.totalPlays,
    required this.uniqueTracks,
    required this.topArtists,
    required this.topAlbums,
  });
}

/// Artist play count
class ArtistPlayCount {
  final String artist;
  final int playCount;

  ArtistPlayCount({
    required this.artist,
    required this.playCount,
  });
}

/// Album play count
class AlbumPlayCount {
  final String album;
  final int playCount;

  AlbumPlayCount({
    required this.album,
    required this.playCount,
  });
}
