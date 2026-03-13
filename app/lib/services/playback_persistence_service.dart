import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/logger.dart';

/// Playback Persistence Service
///
/// Saves and restores playback state across app restarts.
/// Persists:
/// - Current track
/// - Queue
/// - Playback position
/// - Playback settings (shuffle, loop mode)
class PlaybackPersistenceService {
  static const String _keyCurrentTrack = 'playback_current_track';
  static const String _keyQueue = 'playback_queue';
  static const String _keyPosition = 'playback_position_ms';
  static const String _keyIsShuffle = 'playback_is_shuffle';
  static const String _keyLoopMode = 'playback_loop_mode';
  static const String _keyLastPlayed = 'playback_last_played';

  final Future<SharedPreferences> _prefsFuture;
  SharedPreferences? _prefsCache;

  PlaybackPersistenceService(this._prefsFuture);

  Future<SharedPreferences> get _prefs async {
    _prefsCache ??= await _prefsFuture;
    return _prefsCache!;
  }

  /// Save current playback state
  Future<void> savePlaybackState({
    required Track? currentTrack,
    required List<Track> queue,
    required Duration position,
    required bool isShuffle,
    required int loopMode,
  }) async {
    try {
      final prefs = await _prefs;
      // Save current track
      if (currentTrack != null) {
        final trackJson = jsonEncode(currentTrack.toJson());
        await prefs.setString(_keyCurrentTrack, trackJson);
      } else {
        await prefs.remove(_keyCurrentTrack);
      }

      // Save queue
      if (queue.isNotEmpty) {
        final queueJson = jsonEncode(
          queue.map((t) => t.toJson()).toList(),
        );
        await prefs.setString(_keyQueue, queueJson);
      } else {
        await prefs.remove(_keyQueue);
      }

      // Save position
      await prefs.setInt(_keyPosition, position.inMilliseconds);

      // Save shuffle state
      await prefs.setBool(_keyIsShuffle, isShuffle);

      // Save loop mode
      await prefs.setInt(_keyLoopMode, loopMode);

      // Save last played timestamp
      await prefs.setInt(_keyLastPlayed, DateTime.now().millisecondsSinceEpoch);

      Logger.d('Playback state saved', tag: 'Persistence');
    } catch (e, stackTrace) {
      Logger.e('Failed to save playback state', tag: 'Persistence', error: e, stackTrace: stackTrace);
    }
  }

  /// Restore playback state
  Future<PlaybackState?> restorePlaybackState() async {
    try {
      final prefs = await _prefs;
      // Restore current track
      final trackJson = prefs.getString(_keyCurrentTrack);
      Track? currentTrack;
      if (trackJson != null) {
        currentTrack = Track.fromJson(jsonDecode(trackJson));
      }

      // Restore queue
      final queueJson = prefs.getString(_keyQueue);
      List<Track> queue = [];
      if (queueJson != null) {
        final List<dynamic> decoded = jsonDecode(queueJson);
        queue = decoded.map((t) => Track.fromJson(t as Map<String, dynamic>)).toList();
      }

      // Restore position
      final positionMs = prefs.getInt(_keyPosition) ?? 0;
      final position = Duration(milliseconds: positionMs);

      // Restore shuffle state
      final isShuffle = prefs.getBool(_keyIsShuffle) ?? false;

      // Restore loop mode
      final loopMode = prefs.getInt(_keyLoopMode) ?? 0;

      // Restore last played
      final lastPlayedMs = prefs.getInt(_keyLastPlayed);
      final lastPlayed = lastPlayedMs != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastPlayedMs)
          : null;

      // Check if state is still valid (e.g., track still exists)
      if (currentTrack != null && queue.isEmpty) {
        queue = [currentTrack];
      }

      Logger.d('Playback state restored: track=${currentTrack?.title}, queue=${queue.length}, position=${position.inSeconds}s', tag: 'Persistence');

      return PlaybackState(
        currentTrack: currentTrack,
        queue: queue,
        position: position,
        isShuffle: isShuffle,
        loopMode: loopMode,
        lastPlayed: lastPlayed,
      );
    } catch (e, stackTrace) {
      Logger.e('Failed to restore playback state', tag: 'Persistence', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Clear saved playback state
  Future<void> clearPlaybackState() async {
    final prefs = await _prefs;
    await prefs.remove(_keyCurrentTrack);
    await prefs.remove(_keyQueue);
    await prefs.remove(_keyPosition);
    await prefs.remove(_keyIsShuffle);
    await prefs.remove(_keyLoopMode);
    await prefs.remove(_keyLastPlayed);
    Logger.d('Playback state cleared', tag: 'Persistence');
  }

  /// Check if there's a saved state
  Future<bool> hasSavedState() async {
    final prefs = await _prefs;
    return prefs.containsKey(_keyCurrentTrack);
  }

  /// Get time since last played
  Future<Duration?> getTimeSinceLastPlayed() async {
    final prefs = await _prefs;
    final lastPlayedMs = prefs.getInt(_keyLastPlayed);
    if (lastPlayedMs == null) return null;

    final lastPlayed = DateTime.fromMillisecondsSinceEpoch(lastPlayedMs);
    return DateTime.now().difference(lastPlayed);
  }
}

/// Playback state container
class PlaybackState {
  final Track? currentTrack;
  final List<Track> queue;
  final Duration position;
  final bool isShuffle;
  final int loopMode;
  final DateTime? lastPlayed;

  PlaybackState({
    this.currentTrack,
    required this.queue,
    required this.position,
    required this.isShuffle,
    required this.loopMode,
    this.lastPlayed,
  });

  /// Check if state is valid for resuming
  bool get canResume => currentTrack != null && queue.isNotEmpty;

  /// Check if last played was recently (within 24 hours)
  bool get wasPlayedRecently {
    if (lastPlayed == null) return false;
    return DateTime.now().difference(lastPlayed!).inHours < 24;
  }
}
