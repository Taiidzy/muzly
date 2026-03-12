import 'track.dart';

/// Represents a music album
class Album {
  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final String? coverUrl;
  final int releaseYear;
  final int trackCount;
  final List<Track>? tracks;

  Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    this.coverUrl,
    required this.releaseYear,
    this.trackCount = 0,
    this.tracks,
  });

  /// Creates an Album from JSON response
  factory Album.fromJson(Map<String, dynamic> json) {
    List<Track>? tracks;
    if (json['tracks'] != null) {
      tracks = (json['tracks'] as List)
          .map((t) => Track.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return Album(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Album',
      artistId: json['artistId']?.toString() ?? '',
      artistName: json['artistName'] ?? 'Unknown Artist',
      coverUrl: json['coverUrl'] ?? json['coverArtUrl'],
      releaseYear: json['releaseYear'] ?? DateTime.now().year,
      trackCount: json['trackCount'] ?? tracks?.length ?? 0,
      tracks: tracks,
    );
  }

  /// Converts Album to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artistId': artistId,
      'artistName': artistName,
      'coverUrl': coverUrl,
      'releaseYear': releaseYear,
      'trackCount': trackCount,
      'tracks': tracks?.map((t) => t.toJson()).toList(),
    };
  }

  Album copyWith({
    String? id,
    String? title,
    String? artistId,
    String? artistName,
    String? coverUrl,
    int? releaseYear,
    int? trackCount,
    List<Track>? tracks,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      coverUrl: coverUrl ?? this.coverUrl,
      releaseYear: releaseYear ?? this.releaseYear,
      trackCount: trackCount ?? this.trackCount,
      tracks: tracks ?? this.tracks,
    );
  }
}
