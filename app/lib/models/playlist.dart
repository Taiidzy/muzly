import 'track.dart';

/// Represents a playlist
class Playlist {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final String? creatorId;
  final String? creatorName;
  final int trackCount;
  final List<Track>? tracks;
  final bool isPublic;
  final String? kind;

  Playlist({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.creatorId,
    this.creatorName,
    this.trackCount = 0,
    this.tracks,
    this.isPublic = true,
    this.kind,
  });

  /// Creates a Playlist from JSON response (backend format)
  factory Playlist.fromJson(Map<String, dynamic> json) {
    List<Track>? tracks;
    if (json['tracks'] != null) {
      tracks = (json['tracks'] as List)
          .map((t) => Track.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    final isFavorites = json['is_favorites'] == true;
    final visibility = json['visibility'];
    return Playlist(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? 'Unknown Playlist',
      description: json['description'],
      coverUrl: json['coverUrl'] ?? json['coverArtUrl'],
      creatorId: json['creatorId']?.toString() ?? json['user_id']?.toString(),
      creatorName: json['creatorName'] ?? json['user_name'],
      trackCount: json['trackCount'] ?? tracks?.length ?? 0,
      tracks: tracks,
      isPublic: json['isPublic'] ?? (visibility == 'PUBLIC' || visibility == 'public'),
      kind: json['kind'] ?? (isFavorites ? 'favorites' : 'custom'),
    );
  }

  /// Converts Playlist to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'trackCount': trackCount,
      'tracks': tracks?.map((t) => t.toJson()).toList(),
      'isPublic': isPublic,
      'kind': kind,
    };
  }

  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    String? creatorId,
    String? creatorName,
    int? trackCount,
    List<Track>? tracks,
    bool? isPublic,
    String? kind,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      trackCount: trackCount ?? this.trackCount,
      tracks: tracks ?? this.tracks,
      isPublic: isPublic ?? this.isPublic,
      kind: kind ?? this.kind,
    );
  }
}
