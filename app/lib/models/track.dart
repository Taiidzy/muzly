import 'dart:convert';
import '../services/api_config.dart';

/// Represents a music track in the application
class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final int duration;
  final String? coverColor;
  final List<String> tags;
  final String streamUrl;
  final String? cover200Url;
  final String? cover800Url;
  final bool isLiked;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    this.coverColor,
    this.tags = const [],
    required this.streamUrl,
    this.cover200Url,
    this.cover800Url,
    this.isLiked = false,
  });

  // Convenience getters for compatibility
  String get artistName => artist;
  String get albumName => album ?? 'Unknown Album';
  String? get albumArtUrl => cover800Url ?? cover200Url;
  String get audioUrl => streamUrl;
  int get durationMs => duration * 1000;
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Creates a Track from JSON response (backend format)
  factory Track.fromJson(Map<String, dynamic> json) {
    // Parse tags
    List<String> tags = [];
    final tagsData = json['tags'];
    if (tagsData is List) {
      tags = tagsData.map((t) => t.toString()).toList();
    } else if (tagsData is String) {
      try {
        // Try to parse as JSON string
        final parsed = jsonDecode(tagsData);
        if (parsed is List) {
          tags = parsed.map((t) => t.toString()).toList();
        }
      } catch (e) {
        tags = [];
      }
    }

    // Helper to convert relative cover URL to absolute
    String? normalizeCoverUrl(dynamic url) {
      if (url == null || url == '') return null;
      final urlStr = url.toString();
      if (urlStr.startsWith('/')) {
        return '${ApiConfig.baseUrl}$urlStr';
      }
      return urlStr;
    }

    final coverPath =
        json['track_cover_path'] ??
        json['album_cover_path'] ??
        json['artist_avatar_path'];

    final durationMs = json['duration_ms'] ?? json['durationMs'];
    final durationSeconds =
        durationMs is int ? (durationMs / 1000).round() : (json['duration'] ?? 0);

    return Track(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown',
      artist: json['artist'] ?? json['artistName'] ?? 'Unknown Artist',
      album: json['album'] ?? json['albumName'],
      duration: durationSeconds,
      coverColor: json['coverColor'] ?? json['cover_color'],
      tags: tags,
      streamUrl: json['streamUrl'] != null
          ? '${ApiConfig.baseUrl}${json['streamUrl']}'
          : (json['stream_url'] != null
              ? '${ApiConfig.baseUrl}${json['stream_url']}'
              : ''),
      cover200Url: normalizeCoverUrl(
        json['cover200Url'] ??
            json['cover_200_url'] ??
            json['coverUrl'] ??
            (coverPath != null ? '/media/$coverPath' : null),
      ),
      cover800Url: normalizeCoverUrl(
        json['cover800Url'] ??
            json['cover_800_url'] ??
            (coverPath != null ? '/media/$coverPath' : null),
      ),
      isLiked: json['isLiked'] ?? false,
    );
  }

  /// Converts Track to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'coverColor': coverColor,
      'tags': tags,
      'streamUrl': streamUrl,
      'cover200Url': cover200Url,
      'cover800Url': cover800Url,
      'isLiked': isLiked,
    };
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? coverColor,
    List<String>? tags,
    String? streamUrl,
    String? cover200Url,
    String? cover800Url,
    bool? isLiked,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      coverColor: coverColor ?? this.coverColor,
      tags: tags ?? this.tags,
      streamUrl: streamUrl ?? this.streamUrl,
      cover200Url: cover200Url ?? this.cover200Url,
      cover800Url: cover800Url ?? this.cover800Url,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
